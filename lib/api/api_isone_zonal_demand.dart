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

@ApiClass(name: 'isone_zonal_demand', version: 'v1')
class DaLmp {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'zonal_demand';

  static final List<String> _cannonicalZones = [
    'ISONE',
    'ME',
    'NH',
    'VT',
    'CT',
    'RI',
    'SEMA',
    'WCMA',
    'NEMA'
  ];

  DaLmp(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/isone_zonal_demand/v1/zone/isone/market/rt/start/20170101/end/20170101
  @ApiMethod(path: 'zone/{zone}/market/{market}/start/{start}/end/{end}')
  Future<List<Map<String, String>>> apiGetZonalDemand(String zone,
      String market, String start, String end, String bucket) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);

    Stream aux =
        getHourlyData(ptid, component, startDate: startDate, endDate: endDate);
    List out = []; // keep only the hours in the right bucket
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
    return res
        .map((Map e) => {'date': e['key'].toString(), component: e['values']})
        .toList();
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
  Future<List<Map<String, String>>> apiGetHourlyDataByRow(
      String component, int ptid, String start, String end) {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    return getHourlyDataRow(ptid, component,
        startDate: startDate, endDate: endDate);
  }

  /// Get the hourly data by row.  Each row is a Map of {hour, demand}.
  /// [[component]] can be one of 'lmp', 'congestion', 'marginal_loss'.
  Future<List<Map<String, String>>> getHourlyDataRow(String zone,
      {String market, Date startDate, Date endDate}) async {
    Stream res =
        _getHourlyData(zone, market: market, startDate: startDate, endDate: endDate);
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

  /// Workhorse to extract the data ...
  /// returns one element for each day
  Stream _getHourlyData(String zone,
      {String market, Date startDate, Date endDate}) {
    List pipeline = [];
    Map match = {};
    zone = zone.toUpperCase();
    if (_cannonicalZones.contains(zone)) {
      match['zoneName'] = zone;
    }
    Map date = {};
    if (startDate != null) date['\$gte'] = startDate.toString();
    if (endDate != null) date['\$lt'] = endDate.add(1).toString();
    if (date.isNotEmpty) match['date'] = date;

    Map project = {'_id': 0};
    if (market.toUpperCase() == 'RT') {
      project = {'_id': 0, 'hourBeginning': 1, 'RT_Demand': '\$RT_Demand'};
    } else if (market.toUpperCase() == 'DA') {
      project = {'_id': 0, 'hourBeginning': 1, 'DA_Demand': '\$DA_Demand'};
    }
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    return coll.aggregateToStream(pipeline);
  }
}
