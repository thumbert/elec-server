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
  @ApiMethod(path: 'monthly/{component}/ptid/{ptid}/start/{start}/end/{end}/bucket/{bucket}')
  Future<ApiResponse> apiGetMonthlyBucketPrice(
      String component, int ptid, String start, String end, String bucket) async {
    Date startDate = new Date(int.parse(start.substring(0,4)),
      int.parse(start.substring(5,7)), 1);
    Date endDate = new Month(int.parse(end.substring(0,4)),
        int.parse(end.substring(5,7))).endDate;
    Bucket bucketO = Bucket.parse(bucket);

    var aux = await getHourlyPrices(ptid, startDate, endDate, component);
    var out = aux.where((e) {
      TZDateTime hb = TZDateTime.parse(_location, e['hourBeginning']);
      return bucketO.containsHour(new Hour.beginning(hb));
    }).toList();

    // do the monthly aggregation
    Nest _monthlyNest = new Nest()
      ..key((Map e) {
        String hb = e['hourBeginning'];
        return hb.substring(0,7);})
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = _monthlyNest.entries(out);
    var data = res.map((Map e) => {
      'month': e['key'],
      component : e['values']
    }).toList();
    return new ApiResponse()..result = json.encode(data);
  }

  /// http://localhost:8080/dalmp/v1/daily/lmp/ptid/4000/start/20170101/end/20170101/bucket/5x16
  @ApiMethod(path: 'daily/{component}/ptid/{ptid}/start/{start}/end/{end}/bucket/{bucket}')
  Future<ApiResponse> apiGetDailyBucketPrice(
      String component, int ptid, String start, String end, String bucket) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    Bucket bucketO = Bucket.parse(bucket);

    var aux = await getHourlyPrices(ptid, startDate, endDate, component);
    var out = aux.where((e) {
      TZDateTime hb = TZDateTime.parse(_location, e['hourBeginning']);
      return bucketO.containsHour(new Hour.beginning(hb));
    }).toList();

    // do the daily aggregation
    Nest nest = new Nest()
      ..key((Map e) => Date.parse((e['hourBeginning'] as String).substring(0,10)))
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
    return res / i;
  }

  /// http://localhost:8080/dalmp/v1/byrow/congestion/ptid/4000/start/20170101/end/20170101
  @ApiMethod(path: 'byrow/{component}/ptid/{ptid}/start/{start}/end/{end}')
  Future<ApiResponse> apiGetHourlyDataByRow(
      String component, int ptid, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getHourlyPrices(ptid, startDate, endDate, component);
    return new ApiResponse()..result = json.encode(data);
  }

  /// http://localhost:8080/dalmp/v1/bycolumn/congestion/ptid/4000/start/20170101/end/20170101
//  @ApiMethod(path: 'bycolumn/{component}/ptid/{ptid}/start/{start}/end/{end}')
//  Future<Map<String, List<String>>> apiGetHourlyDataByColumn(
//      String component, int ptid, String start, String end) async {
//    Date startDate = Date.parse(start);
//    Date endDate = Date.parse(end);
//    var t2 = await getHourlyDataColumn(ptid, component,
//        startDate: startDate, endDate: endDate);
//    return {'hourBeginning': t2.item1, component: t2.item2};
//  }

  @ApiMethod(path: 'ptids')
  Future<List<int>> allPtids() async {
    Map res = await coll.distinct('ptid');
    return res['values'];
  }

  /// Get the hourly dam data by row.  Each row is a Map of {hour, price}.
  /// [[component]] can be one of 'lmp', 'congestion', 'marginal_loss'.
//  Future<List<Map<String,Object>>> getHourlyDataRow(int ptid, String component,
//      {Date startDate, Date endDate}) async {
//    var res =
//        getHourlyData(ptid, component, startDate: startDate, endDate: endDate);
//    List<Map<String,Object>> out = [];
//    List<String> keys = ['hourBeginning', component];
//    await for (var e in res) {
//      /// each element is a list of 24 hours, prices
//      for (int i = 0; i < e['hourBeginning'].length; i++) {
//        out.add(new Map.fromIterables(keys, [
//          new TZDateTime.from(e['hourBeginning'][i], _location).toString(),
//          e['price'][i]
//        ]));
//      }
//    }
//    return out;
//  }

  /// Get the hourly dam data by column timeseries, two vectors (a vector of
  /// datetimes and a vector of values).
  /// [[component]] can be one of 'lmp', 'congestion', 'marginal_loss'
//  Future<Tuple2<List<String>, List<String>>> getHourlyDataColumn(
//      int ptid, String component,
//      {Date startDate, Date endDate}) async {
//    Stream res =
//        getHourlyData(ptid, component, startDate: startDate, endDate: endDate);
//    List hoursBeginning = [];
//    List prices = [];
//    await for (var e in res) {
//      /// each element is a list of 24 hours, prices
//      for (var dt in e['hourBeginning'])
//        hoursBeginning.add(new TZDateTime.from(dt, _location).toString());
//      for (var price in e['price']) prices.add(price);
//    }
//    return new Tuple2(hoursBeginning, prices);
//  }

  /// Workhorse to extract the data ...
  /// returns one element for each day
  Future getHourlyData(int ptid, String component,
      {Date startDate, Date endDate}) async {
    List pipeline = [];
    Map match = {
      'ptid': {'\$eq': ptid}
    };
//    Map date = {};
//    if (startDate != null) date['\$gte'] = startDate.toString();
//    if (endDate != null) date['\$lt'] = endDate.add(1).toString();
//    if (date.isNotEmpty) match['date'] = date;

//    Map project;
//    if (component == 'lmp') {
//      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$lmp'};
//    } else if (component == 'congestion') {
//      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$congestion'};
//    } else if (component == 'marginal_loss') {
//      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$marginal_loss'};
//    }
    pipeline.add({'\$match': match});
//    pipeline.add({'\$project': project});
    var out = await coll.aggregate(pipeline);
    print(out);
    return out;
  }


  Future<List<Map<String, Object>>> getHourlyPrices(
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
