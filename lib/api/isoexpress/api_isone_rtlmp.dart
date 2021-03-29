library api.isone_rtlmp;

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

class RtLmp {
  mongo.DbCollection coll;
  Location _location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'rt_lmp_hourly';

  RtLmp(mongo.Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get(
        '/monthly/<component>/ptid/<ptid>/start/<start>/end/<end>/bucket/<bucket>',
        (Request request, String component, String ptid, String start,
            String end, String bucket) async {
      var aux = await apiGetMonthlyBucketPrice(
          component, int.parse(ptid), start, end, bucket);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/daily/<component>/ptid/<ptid>/start/<start>/end/<end>/bucket/<bucket>',
        (Request request, String component, String ptid, String start,
            String end, String bucket) async {
      var aux = await apiGetDailyBucketPrice(
          component, int.parse(ptid), start, end, bucket);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/hourly/<component>/ptid/<ptid>/start/<start>/end/<end>/bucket/<bucket>',
        (Request request, String component, String ptid, String start,
            String end, String bucket) async {
      var aux = await apiGetDailyBucketPrice(
          component, int.parse(ptid), start, end, bucket);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// http://localhost:8080/rtlmp/v1/monthly/lmp/ptid/4000/start/201701/end/201701/bucket/5x16
  Future<List<Map<String, dynamic>>> apiGetMonthlyBucketPrice(String component,
      int ptid, String start, String end, String bucket) async {
    var startDate = Date(
        int.parse(start.substring(0, 4)), int.parse(start.substring(4, 6)), 1);
    var endDate =
        Month(int.parse(end.substring(0, 4)), int.parse(end.substring(4, 6)))
            .endDate;
    var bucketO = Bucket.parse(bucket);

    var aux = await getHourlyData(ptid, startDate, endDate, component);
    var out = aux.where((e) {
      var hb = TZDateTime.parse(_location, e['hourBeginning']);
      return bucketO.containsHour(Hour.beginning(hb));
    }).toList();

    /// do the monthly aggregation
    var _monthlyNest = Nest()
      ..key((Map e) {
        String hb = e['hourBeginning'];
        return hb.substring(0, 7);
      })
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = _monthlyNest.entries(out);
    var res2 = res
        .map((Map e) => {'month': e['key'], component: e['values']})
        .toList();
    return res2;
  }

  /// http://localhost:8080/rtlmp/v1/daily/lmp/ptid/4000/start/20170101/end/20170101/bucket/5x16
  Future<List<Map<String, dynamic>>> apiGetDailyBucketPrice(String component,
      int ptid, String start, String end, String bucket) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var bucketO = Bucket.parse(bucket);

    var aux = await getHourlyData(ptid, startDate, endDate, component);
    var out = aux.where((e) {
      var hb = TZDateTime.parse(_location, e['hourBeginning']);
      return bucketO.containsHour(Hour.beginning(hb));
    }).toList();

    /// do the daily aggregation
    var nest = Nest()
      ..key((Map e) {
        String hb = e['hourBeginning'];
        return hb.substring(0, 10);
      })
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = nest.entries(out);
    var data =
        res.map((Map e) => {'date': e['key'], component: e['values']}).toList();
    return data;
  }

  num _mean(Iterable<num> x) {
    var i = 0;
    num res = 0;
    x.forEach((e) {
      res += e;
      i++;
    });
    return res / i;
  }

  /// http://localhost:8080/rtlmp/v1/hourly/congestion/ptid/4000/start/20170101/end/20170101
  Future<List<Map<String, dynamic>>> getHourlyPrices(
      String component, int ptid, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    return getHourlyData(ptid, startDate, endDate, component);
  }

  Future<List<Map<String, dynamic>>> getHourlyData(
      int ptid, Date start, Date end, String component) async {
    var query = mongo.where;
    query = query.eq('ptid', 4000);
    query = query.gte('date', start.toString());
    query = query.lte('date', end.toString());
    query = query.fields(['hourBeginning', component]);
    var data = coll.find(query);
    var out = <Map<String, dynamic>>[];
    var keys = <String>['hourBeginning', component];
    await for (Map e in data) {
      for (var i = 0; i < e['hourBeginning'].length; i++) {
        out.add(Map.fromIterables(keys, [
          TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          e[component][i]
        ]));
      }
    }
    return out;
  }
}
