library api.isone_rtlmp;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:elec/elec.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/utils/api_response.dart';


@ApiClass(name: 'rtlmp', version: 'v1')
class RtLmp {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'rt_lmp_hourly';

  RtLmp(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/rtlmp/v1/monthly/lmp/ptid/4000/start/201701/end/201701/bucket/5x16
  @ApiMethod(path: 'monthly/{component}/ptid/{ptid}/start/{start}/end/{end}/bucket/{bucket}')
  Future<ApiResponse> apiGetMonthlyBucketPrice(
      String component, int ptid, String start, String end, String bucket) async {
    Date startDate = new Date(int.parse(start.substring(0,4)),
      int.parse(start.substring(4,6)), 1);
    Date endDate = new Month(int.parse(end.substring(0,4)),
        int.parse(end.substring(4,6))).endDate;
    Bucket bucketO = Bucket.parse(bucket);

    var aux = await getHourlyData(ptid, startDate, endDate, component);
    var out = aux.where((e) {
      TZDateTime hb = TZDateTime.parse(_location, e['hourBeginning']);
      return bucketO.containsHour(new Hour.beginning(hb));
    }).toList();


    /// do the monthly aggregation
    Nest _monthlyNest = new Nest()
      ..key((Map e) => new Month.fromTZDateTime(e['hourBeginning']))
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = _monthlyNest.entries(out);
    var res2 = res.map((Map e) => {
      'month': (e['key'] as Month).toIso8601String(),
      component : e['values']
    }).toList();
    return new ApiResponse()..result = json.encode(res2);
  }

  
  /// http://localhost:8080/rtlmp/v1/daily/lmp/ptid/4000/start/20170101/end/20170101/bucket/5x16
  @ApiMethod(path: 'daily/{component}/ptid/{ptid}/start/{start}/end/{end}/bucket/{bucket}')
  Future<ApiResponse> apiGetDailyBucketPrice(
      String component, int ptid, String start, String end, String bucket) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    Bucket bucketO = Bucket.parse(bucket);

    var aux = await getHourlyData(ptid, startDate, endDate, component);
    var out = aux.where((e) {
      TZDateTime hb = TZDateTime.parse(_location, e['hourBeginning']);
      return bucketO.containsHour(new Hour.beginning(hb));
    }).toList();


    /// do the daily aggregation
    Nest nest = new Nest()
      ..key((Map e) => new Date.fromTZDateTime(e['hourBeginning']))
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = nest.entries(out);
    var data = res.map((Map e) => {
      'date': e['key'].toString(),
      component : e['values']
    }).toList();
    return new ApiResponse()..result = json.encode(data);
  }

  num _mean(Iterable<num> x) {
    int i = 0;
    num res = 0;
    x.forEach((e) {
      res += e;
      i++;
    });
    return res/i;
  }


  /// http://localhost:8080/rtlmp/v1/hourly/congestion/ptid/4000/start/20170101/end/20170101
  @ApiMethod(path: 'hourly/{component}/ptid/{ptid}/start/{start}/end/{end}')
  Future<ApiResponse> getHourlyPrices(
      String component, int ptid, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getHourlyData(ptid, startDate, endDate, component);
    return new ApiResponse()..result = json.encode(data);
  }


  Future<List<Map<String, dynamic>>> getHourlyData(
      int ptid, Date start, Date end, String component) async {
    SelectorBuilder query = where;
    query = query.eq('ptid', 4000);
    query = query.gte('date', start.toString());
    query = query.lte('date', end.toString());
    query = query.fields(['hourBeginning', component]);
    var data = coll.find(query);
    var out = <Map<String, dynamic>>[];
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

