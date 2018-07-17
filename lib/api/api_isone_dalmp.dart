library api.isone_dalmp;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:elec/elec.dart';
import 'package:table/table.dart';

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
  Future<List<Map<String, String>>> apiGetMonthlyBucketPrice(
      String component, int ptid, String start, String end, String bucket) async {
    Date startDate = new Date(int.parse(start.substring(0,4)),
      int.parse(start.substring(4,6)), 1);
    Date endDate = new Month(int.parse(end.substring(0,4)),
        int.parse(end.substring(4,6))).endDate;
    Bucket bucketO = Bucket.parse(bucket);

    Stream aux = getHourlyData(ptid, component, startDate: startDate, endDate: endDate);
    List out = [];  // keep only the hours in the right bucket
    List keys = ['hourBeginning', component];
    await for (var e in aux) {
      /// each element is a list of 24 hours, prices
      for (int i = 0; i < e['hourBeginning'].length; i++) {
        TZDateTime hb = new TZDateTime.from(e['hourBeginning'][i], _location);
        if (bucketO.containsHour(new Hour.beginning(hb))) {
          out.add(new Map.fromIterables(keys, [
            new TZDateTime.from(e['hourBeginning'][i], _location),
            e['price'][i]
          ]));
        }
      }
    }
    /// do the monthly aggregation
    Nest _monthlyNest = new Nest()
      ..key((Map e) => new Month.fromTZDateTime(e['hourBeginning']))
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = _monthlyNest.entries(out);
    return res.map((Map e) => {
      'month': (e['key'] as Month).toIso8601String(),
      component : e['values']
    }).toList();
  }
  
  /// http://localhost:8080/dalmp/v1/daily/lmp/ptid/4000/start/20170101/end/20170101/bucket/5x16
  @ApiMethod(path: 'daily/{component}/ptid/{ptid}/start/{start}/end/{end}/bucket/{bucket}')
  Future<List<Map<String, String>>> apiGetDailyBucketPrice(
      String component, int ptid, String start, String end, String bucket) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    Bucket bucketO = Bucket.parse(bucket);

    Stream aux = getHourlyData(ptid, component, startDate: startDate, endDate: endDate);
    List out = [];  // keep only the hours in the right bucket
    List keys = ['hourBeginning', component];
    await for (var e in aux) {
      /// each element is a list of 24 hours, prices
      for (int i = 0; i < e['hourBeginning'].length; i++) {
        TZDateTime hb = new TZDateTime.from(e['hourBeginning'][i], _location);
        if (bucketO.containsHour(new Hour.beginning(hb))) {
          out.add(new Map.fromIterables(keys, [
            new TZDateTime.from(e['hourBeginning'][i], _location),
            e['price'][i]
          ]));
        }
      }
    }
    /// do the daily aggregation
    Nest nest = new Nest()
      ..key((Map e) => new Date.fromTZDateTime(e['hourBeginning']))
      ..rollup((Iterable x) => _mean(x.map((e) => e[component])));
    List<Map> res = nest.entries(out);
    return res.map((Map e) => {
      'date': e['key'].toString(),
      component : e['values']
    }).toList();
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



  /// http://localhost:8080/dalmp/v1/byrow/congestion/ptid/4000/start/20170101/end/20170101
  @ApiMethod(path: 'byrow/{component}/ptid/{ptid}/start/{start}/end/{end}')
  Future<List<Map<String, String>>> apiGetHourlyDataByRow(
      String component, int ptid, String start, String end) {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    return getHourlyDataRow(ptid, component,
        startDate: startDate, endDate: endDate);
  }

  /// http://localhost:8080/dalmp/v1/bycolumn/congestion/ptid/4000/start/20170101/end/20170101
  @ApiMethod(path: 'bycolumn/{component}/ptid/{ptid}/start/{start}/end/{end}')
  Future<Map<String, List<String>>> apiGetHourlyDataByColumn(
      String component, int ptid, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var t2 = await getHourlyDataColumn(ptid, component,
        startDate: startDate, endDate: endDate);
    return {'hourBeginning': t2.item1, component: t2.item2};
  }


  @ApiMethod(path: 'ptids')
  Future<List<int>> allPtids() async {
    Map res = await coll.distinct('ptid');
    return res['values'];
  }


  /// Get the hourly dam data by row.  Each row is a Map of {hour, price}.
  /// [[component]] can be one of 'lmp', 'congestion', 'marginal_loss'.
  Future<List<Map<String, String>>> getHourlyDataRow(int ptid, String component,
      {Date startDate, Date endDate}) async {
    Stream res =
        getHourlyData(ptid, component, startDate: startDate, endDate: endDate);
    List out = [];
    List keys = ['hourBeginning', component];
    await for (var e in res) {
      /// each element is a list of 24 hours, prices
      for (int i = 0; i < e['hourBeginning'].length; i++) {
        out.add(new Map.fromIterables(keys, [
          new TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          e['price'][i]
        ]));
      }
    }
    return out;
  }

  /// Get the hourly dam data by column timeseries, two vectors (a vector of
  /// datetimes and a vector of values).
  /// [[component]] can be one of 'lmp', 'congestion', 'marginal_loss'
  Future<Tuple2<List<String>, List<String>>> getHourlyDataColumn(
      int ptid, String component,
      {Date startDate, Date endDate}) async {
    Stream res =
        getHourlyData(ptid, component, startDate: startDate, endDate: endDate);
    List hoursBeginning = [];
    List prices = [];
    await for (var e in res) {
      /// each element is a list of 24 hours, prices
      for (var dt in e['hourBeginning'])
        hoursBeginning.add(new TZDateTime.from(dt, _location).toString());
      for (var price in e['price']) prices.add(price);
    }
    return new Tuple2(hoursBeginning, prices);
  }

  /// Workhorse to extract the data ...
  /// returns one element for each day
  Stream getHourlyData(int ptid, String component,
      {Date startDate, Date endDate}) {
    List pipeline = [];
    Map match = {
      'ptid': {'\$eq': ptid}
    };
    Map date = {};
    if (startDate != null) date['\$gte'] = startDate.toString();
    if (endDate != null) date['\$lt'] = endDate.add(1).toString();
    if (date.isNotEmpty) match['date'] = date;

    Map project;
    if (component == 'lmp') {
      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$lmp'};
    } else if (component == 'congestion') {
      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$congestion'};
    } else if (component == 'marginal_loss') {
      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$marginal_loss'};
    }
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    return coll.aggregateToStream(pipeline);
  }
}

