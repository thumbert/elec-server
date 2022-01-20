library api.nyiso.dalmp;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:table/table.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class DaLmp {
  late mongo.DbCollection coll;
  late Location _location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'da_lmp_hourly';

  DaLmp(mongo.Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('America/New_York');
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
      var aux = await getDailyBucketPrice(
          component, int.parse(ptid), start, end, bucket);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// get daily 7x24 price for all ptids between a start and end date
    router.get('/daily/mean/<component>/start/<start>/end/<end>',
        (Request request, String component, String start, String end) async {
      var aux = await dailyPriceByPtid(component, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// get hourly prices for one ptid
    router.get('/hourly/<component>/ptid/<ptid>/start/<start>/end/<end>',
        (Request request, String component, String ptid, String start,
            String end) async {
      var aux = await getHourlyPrices(component, int.parse(ptid), start, end);
      return Response.ok(json.encode(aux), headers: headers);
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

  /// Return a list of elements like
  /// ```
  /// {'date': '2020-01-12', 'lmp': 75.21},
  /// ```
  /// http://localhost:8080/nyiso/dalmp/v1/daily/lmp/ptid/4000/start/20170101/end/20170101/bucket/5x16
  Future<List<Map<String, dynamic>>> getDailyBucketPrice(String component,
      int ptid, String start, String end, String bucket) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var bucketO = Bucket.parse(bucket);

    var days = startDate.upTo(endDate);
    var groups = Map.fromIterables(days.map((e) => e.toString()),
        List.generate(days.length, (index) => <num>[]));

    var aux = await getHourlyData(ptid, startDate, endDate, component);
    for (var e in aux.entries) {
      var date = Date(int.parse(e.key.substring(0, 4)),
          int.parse(e.key.substring(5, 7)), int.parse(e.key.substring(8)),
          location: NewYorkIso.location);
      var currentHour = Hour.beginning(date.start);
      for (var v in e.value) {
        if (bucketO.containsHour(currentHour)) {
          groups[e.key]!.add(v);
        }
        currentHour = currentHour.next;
      }
    }

    // calculate the mean for each day
    return groups.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => {
              'date': e.key,
              component: _mean(e.value),
            })
        .toList();
  }

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
  /// [component] needs to be one of 'lmp', 'congestion', 'losses'
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
