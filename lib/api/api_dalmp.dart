library api.dalmp;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A generic API for DA LMP prices that support multiple regions
class DaLmp {
  late mongo.DbCollection coll;
  final Iso iso;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'da_lmp_hourly';

  DaLmp(mongo.Db db, {required this.iso}) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// get monthly price for bucket for one ptid
    router.get(
        '/monthly/<component>/ptid/<ptid>/start/<start>/end/<end>/bucket/<bucket>',
        (Request request, String component, String ptid, String start,
            String end, String bucket) async {
      var aux = await getMonthlyBucketPrice(
          component, int.parse(ptid), start, end, bucket);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// get daily price for bucket for one ptid
    router.get(
        '/daily/<component>/ptid/<ptid>/start/<start>/end/<end>/bucket/<bucket>',
        (Request request, String component, String ptid, String start,
            String end, String bucket) async {
      var aux = await getDailyBucketPriceSeveral(
          component,
          [int.parse(ptid)],
          Date.parse(start, location: UTC),
          Date.parse(end, location: UTC),
          Bucket.parse(bucket));
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// get daily price for bucket for several ptids
    /// http://localhost:8080/nyiso/dalmp/v1/daily/lmp/ptids/61752,61758/start/20170101/end/20170101/bucket/5x16
    router.get(
        '/daily/<component>/ptids/<ptids>/start/<start>/end/<end>/bucket/<bucket>',
        (Request request, String component, String ptids, String start,
            String end, String bucket) async {
      var _ptids = ptids.split(',').map((e) => int.parse(e)).toList();
      var _start = Date.parse(start, location: UTC);
      var _end = Date.parse(end, location: UTC);
      var _bucket = Bucket.parse(bucket);

      var aux = await getDailyBucketPriceSeveral(
          component, _ptids, _start, _end, _bucket);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// get daily 7x24 price for all ptids between a start and end date
    router.get('/daily/mean/<component>/start/<start>/end/<end>',
        (Request request, String component, String start, String end) async {
      var aux = await dailyPriceByPtid(component, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get hourly prices for one ptid
    /// Return a Map in this form
    /// ```
    /// {
    ///   '2021-01-01': <num>[45.67, 32.74, ...],
    ///   '2021-01-02': <num>[42.83, 37.35, ...],
    ///   ...
    /// }
    /// ```
    router.get('/hourly/<component>/ptid/<ptid>/start/<start>/end/<end>',
        (Request request, String component, String ptid, String start,
            String end) async {
      var aux = await getHourlyPrices(component, int.parse(ptid), start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get hourly prices for multiple ptids
    /// Return a list of maps with elements like
    /// ```
    /// {
    ///   'hourBeginning': '2021-01-01 00:00:00-05:00',
    ///   'ptid': 61754,
    ///   'lmp': 19.16,
    /// }
    /// ```
    router.get(
        '/hourly/<component>/ptids/<ptids>/start/<start>/end/<end>',
            (Request request, String component, String ptids, String start, String end) async {
          var ptids0 = ptids.split(',').map((e) => int.parse(e)).toList();
          var startDate = Date.parse(start, location: UTC);
          var endDate = Date.parse(end, location: UTC);

          var aux = await getHourlyDataSeveral(ptids0, startDate, endDate, component);
          var out = <Map<String, dynamic>>[];

          var groups = groupBy(aux, (Map e) => e['date']);
          for (var yyyymmdd in groups.keys) {
            var date = Date.fromIsoString(yyyymmdd, location: IsoNewEngland.location);
            var hours = date.hours();
            var group = groups[yyyymmdd]!;
            for (var i=0; i<hours.length; i++) {
              for (var e in group) {
                out.add({
                  'hourBeginning': hours[i].start.toIso8601String(),
                  'ptid': e['ptid'],
                  component:  e[component][i],
                });
              }
            }
          }

          return Response.ok(json.encode(out), headers: headers);
        });


    /// Get all the existing ptids in the collection, sorted
    router.get('/ptids', (Request request) async {
      var res = await (allPtids() as FutureOr<List<int>>);
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    return router;
  }

  /// Return a list with elements:
  /// ```
  /// {'month': '2020-01', 'lmp': 27.89},
  /// ...
  /// ```
  /// http://localhost:8080/nyiso/dalmp/v1/monthly/lmp/ptid/61757/start/201701/end/201701/bucket/5x16
  Future<List<Map<String, dynamic>>> getMonthlyBucketPrice(String component,
      int ptid, String start, String end, String bucket) async {
    start = start.replaceAll('-', '');
    end = end.replaceAll('-', '');
    var startMonth = Month.utc(
        int.parse(start.substring(0, 4)), int.parse(start.substring(4, 6)));
    var endMonth = Month.utc(
        int.parse(end.substring(0, 4)), int.parse(end.substring(4, 6)));

    var startDate = startMonth.startDate;
    var endDate = endMonth.endDate;
    var bucketO = Bucket.parse(bucket);

    /// special case for atc bucket
    if (bucketO == Bucket.atc) {
      var aux =
          await getMonthlyAtcPrices([ptid], startMonth, endMonth, component);
      return [
        for (var e in aux) {'month': e['month'], component: e[component]}
      ];
    }

    /// filter the hourly data by the bucket and accumulate in [groups]
    var months = startMonth.upTo(endMonth);
    var groups = Map.fromIterables(months.map((e) => e.toIso8601String()),
        List.generate(months.length, (index) => <num>[]));

    var data = await getHourlyData(ptid, startDate, endDate, component);
    for (var e in data.entries) {
      var date = Date(int.parse(e.key.substring(0, 4)),
          int.parse(e.key.substring(5, 7)), int.parse(e.key.substring(8)),
          location: NewYorkIso.location);
      var currentHour = Hour.beginning(date.start);
      for (var v in e.value) {
        var yyyymm = e.key.substring(0, 7);
        if (bucketO.containsHour(currentHour)) {
          groups[yyyymm]!.add(v);
        }
        currentHour = currentHour.next;
      }
    }

    // calculate the mean for each month
    return groups.entries
        .map((e) => {
              'month': e.key,
              component: _mean(e.value),
            })
        .toList();
  }

  /// Get daily bucket price for one ptid.
  /// Return a list of elements like
  /// ```
  /// {'ptid': 61752, 'date': '2020-01-12', 'lmp': 75.21},
  /// ```
  Future<List<Map<String, dynamic>>> getDailyBucketPriceSeveral(
      String component,
      List<int> ptids,
      Date start,
      Date end,
      Bucket bucket) async {
    /// special case for atc bucket
    if (bucket == Bucket.atc) {
      return getDailyAtcPrices(ptids, start, end, component);
    }

    var out = <Map<String, dynamic>>[];
    var aux = await getHourlyDataSeveral(ptids, start, end, component);
    // group by date to get the bucket hour index only once for speed
    var groups = groupBy(aux, (Map e) => e['date']);
    for (var yyyymm in groups.keys) {
      var date = Date(int.parse(yyyymm.substring(0, 4)),
          int.parse(yyyymm.substring(5, 7)), int.parse(yyyymm.substring(8)),
          location: iso.preferredTimeZoneLocation);
      var hours = date.hours();
      var index = List.generate(hours.length, (i) => i)
          .where((i) => bucket.containsHour(hours[i]))
          .toList();
      if (index.isNotEmpty) {
        for (var e in groups[yyyymm]!) {
          out.add({
            'date': yyyymm,
            if (ptids.length > 1) 'ptid': e['ptid'],
            component: _mean(index.map((i) => e[component][i])),
          });
        }
      }
    }
    return out;
  }

  /// Get hourly prices for one ptid.
  /// Each element of the Map is 'yyyy-mm-dd' -> <num>[...]
  /// http://localhost:8080/nyiso/dalmp/v1/hourly/congestion/ptid/61757/start/20190101/end/20190101
  Future<Map<String, List<num>>> getHourlyPrices(
      String component, int ptid, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    return getHourlyData(ptid, startDate, endDate, component);
  }

  /// Get all ptids in the database
  Future<List<int>?> allPtids() async {
    Map res = await coll.distinct('ptid');
    return res['values'] as List<int>?;
  }

  /// Calculate the daily 7x24 price by ptid between start/end dates
  Future<List<Map<String, dynamic>>> dailyPriceByPtid(
      String component, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);

    var pipeline = <Map<String, Object>>[];
    pipeline.addAll([
      {
        '\$match': {
          'date': {
            '\$lte': endDate.toString(),
            '\$gte': startDate.toString(),
          },
        }
      },
      {
        '\$group': {
          '_id': {
            'date': '\$date',
            'ptid': '\$ptid',
            component: {'\$avg': '\$$component'},
          }
        }
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          'ptid': '\$_id.ptid',
          component: '\$_id.$component',
        }
      },
      {
        '\$sort': {
          'ptid': 1,
          'date': 1,
        }
      }
    ]);

    var res = await coll.aggregateToStream(pipeline).toList();
    return res;
  }

  ///
  /// [component] needs to be one of 'lmp', 'congestion', 'losses'.
  /// Return a Map with all elements in this form:
  /// ```
  ///   '2020-01-09': <num>[...],
  /// ```
  Future<Map<String, List<num>>> getHourlyData(
      int ptid, Date start, Date end, String component) async {
    var query = mongo.where
      ..eq('ptid', ptid)
      ..gte('date', start.toString())
      ..lte('date', end.toString())
      ..fields(['date', component])
      ..sortBy('date');
    var data = await coll.find(query).toList();
    var out = <String, List<num>>{};
    for (Map e in data) {
      out[e['date']] = <num>[...e[component]];
    }
    return out;
  }

  ///
  /// [component] needs to be one of 'lmp', 'congestion', 'losses'
  /// Return a Map with all elements in this form:
  /// ```
  /// {
  ///   'ptid': 61752,
  ///   'date': '2020-01-09',
  ///   component: <num>[...],
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getHourlyDataSeveral(
      List<int> ptids, Date start, Date end, String component) async {
    var query = mongo.where
      ..oneFrom('ptid', ptids)
      ..gte('date', start.toString())
      ..lte('date', end.toString())
      ..fields(['ptid', 'date', component])
      ..excludeFields(['_id'])
      ..sortBy('date');
    return coll.find(query).toList();
  }

  /// Get daily 7x24 prices for several ptids.  Do the aggregation in Mongo
  /// for speed.  Return a list with elements in this form
  /// ```
  /// {
  ///   'ptid': 61752,
  ///   'date': '2019-01-01',
  ///   'congestion': -1.0204166666666667,
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getDailyAtcPrices(
      List<int> ptids, Date start, Date end, String component) async {
    var pipeline = <Map<String, Object>>[
      {
        '\$match': {
          'date': {
            '\$lte': end.toString(),
            '\$gte': start.toString(),
          },
          'ptid': {
            '\$in': ptids,
          }
        }
      },
      {
        '\$group': {
          '_id': {
            'date': '\$date',
            'ptid': '\$ptid',
            component: {'\$avg': '\$$component'},
          }
        }
      },
      {
        '\$project': {
          '_id': 0,
          'ptid': '\$_id.ptid',
          'date': '\$_id.date',
          component: '\$_id.$component',
        }
      },
      {
        '\$sort': {
          'ptid': 1,
          'date': 1,
        }
      }
    ];

    var res = await coll.aggregateToStream(pipeline).toList();
    return res;
  }

  /// Calculate monthly 7x24 average prices directly in Mongo for several ptids
  /// Return a list of documents in this form
  /// ```
  ///   'month': '2019-01',
  ///   'ptid': 61752,
  ///   'congestion': -4.7663306451612915,
  /// ```
  Future<List<Map<String, dynamic>>> getMonthlyAtcPrices(
      List<int> ptids, Month start, Month end, String component) async {
    var pipeline = <Map<String, Object>>[
      {
        '\$match': {
          'date': {
            '\$lte': end.endDate.toString(),
            '\$gte': start.startDate.toString(),
          },
          'ptid': {
            '\$in': ptids,
          }
        }
      },
      {
        '\$unwind': '\$$component',
      },
      {
        '\$group': {
          '_id': {
            'month': {
              '\$substr': ['\$date', 0, 7]
            },
            'ptid': '\$ptid',
          },
          component: {'\$avg': '\$$component'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'month': '\$_id.month',
          'ptid': '\$_id.ptid',
          component: '\$$component',
        }
      },
      {
        '\$sort': {
          'ptid': 1,
          'month': 1,
        }
      }
    ];

    var res = await coll.aggregateToStream(pipeline).toList();
    return res;
  }

  num _mean(Iterable<num?> x) {
    var i = 0;
    num res = 0;
    for (var e in x) {
      res += e!;
      i++;
    }
    return res / i;
  }
}
