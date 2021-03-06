library api.isone_dalmp;

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

    /// get hourly prices for one ptid in compact form (?? what is that)
    router
        .get('/hourly/<component>/ptid/<ptid>/start/<start>/end/<end>/compact',
            (Request request, String component, String ptid, String start,
                String end) async {
      var aux =
          await getHourlyPricesCompact(component, int.parse(ptid), start, end);
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

  /// http://localhost:8080/dalmp/v1/monthly/lmp/ptid/4000/start/201701/end/201701/bucket/5x16
  Future<List<Map<String, dynamic>>> getMonthlyBucketPrice(String component,
      int ptid, String start, String end, String bucket) async {
    var startDate = Date.parse(start.replaceAll('-', '') + '01');
    var aux = Date.parse(end.replaceAll('-', '') + '01');
    var endDate = Month.utc(aux.year, aux.month).endDate;
    var bucketO = Bucket.parse(bucket);

    var data = await getHourlyData(ptid, startDate, endDate, component);
    var out = data.where((e) {
      var hb = TZDateTime.parse(_location, e['hourBeginning'] as String);
      return bucketO.containsHour(Hour.beginning(hb));
    }).toList();

    // do the monthly aggregation
    var _monthlyNest = Nest()
      ..key((Map e) => (e['hourBeginning'] as String).substring(0, 7))
      ..rollup((Iterable x) => _mean(x.map((e) => e[component] as num?)));
    var res = _monthlyNest.entries(out) as List<Map>;
    return res
        .map((Map e) => {'month': e['key'], component: e['values']})
        .toList();
  }

  /// http://localhost:8080/dalmp/v1/daily/lmp/ptid/4000/start/20170101/end/20170101/bucket/5x16
  Future<List<Map<String, dynamic>>> getDailyBucketPrice(String component,
      int ptid, String start, String end, String bucket) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var bucketO = Bucket.parse(bucket);

    var aux = await getHourlyData(ptid, startDate, endDate, component);
    var out = aux.where((e) {
      var hb = TZDateTime.parse(_location, e['hourBeginning'] as String);
      return bucketO.containsHour(Hour.beginning(hb));
    }).toList();

    // do the daily aggregation
    var nest = Nest()
      ..key((Map e) => (e['hourBeginning'] as String).substring(0, 10))
      ..rollup((Iterable x) => _mean(x.map((e) => e[component] as num?)));
    var res = nest.entries(out) as List<Map>;
    return res
        .map((Map e) => {'date': e['key'], component: e['values']})
        .toList();
  }

  ///
  /// http://localhost:8080/dalmp/v1/hourly/congestion/ptid/4000/start/20170101/end/20170101
  Future<List<Map<String, Object?>>> getHourlyPrices(
      String component, int ptid, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    return getHourlyData(ptid, startDate, endDate, component);
  }

  ///
  /// http://localhost:8080/dalmp/v1/hourly/congestion/ptid/4000/start/20170101/end/20170101/compact
  Future<List<double?>> getHourlyPricesCompact(
      String component, int ptid, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getHourlyData(ptid, startDate, endDate, component);
    return data.map((e) => e[component] as double?).toList();
  }

  /// Get all ptids in the database
  Future<List<int>?> allPtids() async {
    Map res = await coll.distinct('ptid');
    return res['values'] as List<int>?;
  }

  /// Average 7x24 price by ptid between the start/end dates
  Future<List<Map<String, dynamic>>> dailyPriceByPtid(
      String component, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);

    var pipeline = <Map<String,Object>>[];
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

  Future<List<Map<String, dynamic>>> getHourlyData(
      int ptid, Date start, Date end, String component) async {
    var query = mongo.where
      ..eq('ptid', ptid)
      ..gte('date', start.toString())
      ..lte('date', end.toString())
      ..fields(['hourBeginning', component]);
    var data = coll.find(query);
    var out = <Map<String, dynamic>>[];
    var keys = ['hourBeginning', component];
    await for (Map e in data) {
      var hours = e['hourBeginning'] as List;
      for (var i = 0; i < hours.length; i++) {
        out.add(Map.fromIterables(keys, [
          TZDateTime.from(hours[i] as DateTime, _location).toString(),
          e[component][i]
        ]));
      }
    }
    return out;
  }

  num _mean(Iterable<num?> x) {
    var i = 0;
    num res = 0;
    x.forEach((e) {
      res += e!;
      i++;
    });
    return res / i;
  }
}
