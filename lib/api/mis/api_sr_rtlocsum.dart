library api.mis.sr_rtlocsum;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';

@ApiClass(name: 'sr_rtlocsum', version: 'v1')
class SrRtLocSum {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'sr_rtlocsum';

  SrRtLocSum(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/sr_rtlocsum/v1/tab/0/locationId/401/column/Real Time Load Obligation/start/20170101/end/20170101
  @ApiMethod(
      path:
          'tab/{tab}/locationId/{locationId}/column/{column}/start/{start}/end/{end}')
  /// Get one column in this tab for a given location.
  Future<List<Map<String, String>>> apiGetColumn (
      int tab, int locationId, String column, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    Stream data = getData(tab, locationId, column, startDate, endDate);
    List out = [];
    List keys = ['hourBeginning', column];
    await for (Map e in data) {
      for (int i=0; i<e['hourBeginning'].length; i++){
        out.add(new Map.fromIterables(keys, [
          new TZDateTime.from(e['hourBeginning'][i], _location),
          e[column][i]
        ]));
      }
    }
    return out;
  }

  /// Workhorse to extract the data ...
  /// returns one element for each day
  Stream getData(
      int tab, int locationId, String column, Date startDate, Date endDate) {
    List pipeline = [];
    pipeline.add({
      '\$match': {
        'tab': {'\$eq': tab},
        'Location ID': {'\$eq': locationId},
        'date': {
          '\$gte': startDate.toString(),
          '\$lte': endDate.toString(),
        },
      }
    });
    pipeline.add({'\$project': {
      '_id': 0,
      'hourBeginning': 1,
      '${column}': 1,
    }});
    print(pipeline);
    return coll.aggregateToStream(pipeline);
  }
}
