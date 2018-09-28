library api.isone_dalmp;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:table/table.dart';
import '../src/utils/api_response.dart';

@ApiClass(name: 'dalmp', version: 'v1')
class DaLmp {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'da_lmp_hourly';

  DaLmp(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/dalmp/v1/monthly/lmp/ptid/4000/start/201701/end/201701/bucket/5x16
  @ApiMethod(
      path:
          'monthly/{component}/ptid/{ptid}/start/{start}/end/{end}/bucket/{bucket}')
  Future<ApiResponse> getMonthlyBucketPrice(String component, int ptid,
      String start, String end, String bucket) async {
    var startDate = Date.parse(start.replaceAll('-', '') + '01');
    var aux = Date.parse(end.replaceAll('-', '') + '01');
    var endDate = new Month(aux.year, aux.month).endDate;
    Bucket bucketO = Bucket.parse(bucket);

    var data = await getHourlyData(ptid, startDate, endDate, component);
    var out = data.where((e) {
      TZDateTime hb = TZDateTime.parse(_location, e['hourBeginning']);
      return bucketO.containsHour(new Hour.beginning(hb));
    }).toList();

    // do the monthly aggregation
    Nest _monthlyNest = new Nest()
      ..key((Map e) {
        String hb = e['hourBeginning'];
        return hb.substring(0, 7);
      })
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = _monthlyNest.entries(out);
    var res2 = res
        .map((Map e) => {'month': e['key'], component: e['values']})
        .toList();
    return new ApiResponse()..result = json.encode(res2);
  }

  /// http://localhost:8080/dalmp/v1/daily/lmp/ptid/4000/start/20170101/end/20170101/bucket/5x16
  @ApiMethod(
      path:
          'daily/{component}/ptid/{ptid}/start/{start}/end/{end}/bucket/{bucket}')
  Future<ApiResponse> getDailyBucketPrice(String component, int ptid,
      String start, String end, String bucket) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    Bucket bucketO = Bucket.parse(bucket);

    var aux = await getHourlyData(ptid, startDate, endDate, component);
    var out = aux.where((e) {
      TZDateTime hb = TZDateTime.parse(_location, e['hourBeginning']);
      return bucketO.containsHour(new Hour.beginning(hb));
    }).toList();

    // do the daily aggregation
    Nest nest = new Nest()
      ..key((Map e) =>
          Date.parse((e['hourBeginning'] as String).substring(0, 10)))
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = nest.entries(out);
    var data = res
        .map((Map e) => {'date': e['key'].toString(), component: e['values']})
        .toList();
    return new ApiResponse()..result = json.encode(data);
  }

  num _mean(Iterable<num> x) {
    int i = 0;
    num res = 0;
    x.forEach((e) {
      res += e;
      i++;
    });
    return res / i;
  }

  /// http://localhost:8080/dalmp/v1/byrow/congestion/ptid/4000/start/20170101/end/20170101
  @ApiMethod(path: 'component/{component}/ptid/{ptid}/start/{start}/end/{end}')
  Future<ApiResponse> getHourlyPrices(
      String component, int ptid, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getHourlyData(ptid, startDate, endDate, component);
    return new ApiResponse()..result = json.encode(data);
  }

  /// http://localhost:8080/dalmp/v1/byrow/congestion/ptid/4000/start/20170101/end/20170101/compact
  @ApiMethod(path: 'component/{component}/ptid/{ptid}/start/{start}/end/{end}/compact')
  Future<List<double>> getHourlyPricesCompact(
      String component, int ptid, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getHourlyData(ptid, startDate, endDate, component);
    return data.map((e) => e[component] as double).toList();
  }


  @ApiMethod(path: 'ptids')
  Future<List<int>> allPtids() async {
    Map res = await coll.distinct('ptid');
    return res['values'];
  }

  Future<List<Map<String, Object>>> getHourlyData(
      int ptid, Date start, Date end, String component) async {
    SelectorBuilder query = where;
    query = query.eq('ptid', 4000);
    query = query.gte('date', start.toString());
    query = query.lte('date', end.toString());
    query = query.fields(['hourBeginning', component]);
    var data = coll.find(query);
    var out = <Map<String, Object>>[];
    List<String> keys = ['hourBeginning', component];
    await for (Map e in data) {
      for (int i = 0; i < e['hourBeginning'].length; i++) {
        out.add(new Map.fromIterables(keys, [
          new TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          e[component][i]
        ]));
      }
    }
    return out;
  }
}
