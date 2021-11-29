library api.isone_zonal_demand;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';

// @ApiClass(name: 'zonal_demand', version: 'v1')
class ZonalDemand {
  late DbCollection coll;
  late Location _location;
  final DateFormat fmt = DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'zonal_demand';

  static final List<String> _canonicalZones = [
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

  ZonalDemand(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('America/New_York');
  }

  /// http://localhost:8080/zonal_demand/v1/zone/isone/start/20170101/end/20170101
  // @ApiMethod(path: 'zone/{zone}/start/{start}/end/{end}')
  Future<List<Map<String, String>>> apiGetZonalDemand(
      String zone, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);

    Stream aux = _getHourlyData(zone, startDate: startDate, endDate: endDate);
    var out = [];
    var keys = [
      'hourBeginning',
      'DA_Demand',
      'RT_Demand',
      'DryBulb',
      'DewPoint'
    ];
    await for (var e in aux) {
      /// each element is a list of 24 hours, prices
      for (var i = 0; i < e['hourBeginning'].length; i++) {
        out.add(Map.fromIterables(keys, [
          TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          e['DA_Demand'][i],
          e['RT_Demand'][i],
          e['DryBulb'][i],
          e['DewPoint'][i],
        ]));
      }
    }
    return out as FutureOr<List<Map<String, String>>>;
  }


  /// Workhorse to extract the data ...
  /// returns one element for each day
  Stream _getHourlyData(String zone, {Date? startDate, Date? endDate}) {
    var pipeline = [];
    var match = {};
    zone = zone.toUpperCase();
    if (_canonicalZones.contains(zone)) match['zoneName'] = zone;

    var date = {};
    if (startDate != null) date['\$gte'] = startDate.toString();
    if (endDate != null) date['\$lt'] = endDate.add(1).toString();
    if (date.isNotEmpty) match['date'] = date;

    pipeline.add({'\$match': match});
    pipeline.add({
      '\$project': {'_id': 0}
    });
    return coll.aggregateToStream(pipeline as List<Map<String, Object>>);
  }
}
