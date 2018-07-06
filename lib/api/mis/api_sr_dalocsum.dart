library api.mis.sr_dalocsum;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';


@ApiClass(name: 'sr_dalocsum', version: 'v1')
class SrDaLocSum {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'sr_dalocsum';

  SrDaLocSum(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/sr_dalocsum/v1/accountId/000050428/locationId/4004/column/Day Ahead Cleared Demand Bids/start/20170601/end/20170601
  @ApiMethod(
      path:
      'accountId/{accountId}/locationId/{locationId}/column/{column}/start/{start}/end/{end}')
  /// Get one column in this tab for a given location.
  Future<List<Map<String, String>>> apiGetColumnTab0 (String accountId,
      int locationId, String column, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    Stream data = _getData0(accountId, locationId, column, startDate, endDate);
    List out = [];
    List keys = ['hourBeginning', 'version', column];
    await for (Map e in data) {
      for (int i=0; i<e['hourBeginning'].length; i++){
        out.add(new Map.fromIterables(keys, [
          new TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          new TZDateTime.from(e['version'], _location).toString(),
          e[column][i]
        ]));
      }
    }
    return out;
  }

  /// http://localhost:8080/sr_dalocsum/v1/accountId/000050428/locationId/4004/column/Day Ahead Clearead Demand Bids/start/20180101/end/20180101
  @ApiMethod(
      path:
      'accountId/{accountId}/subaccountId/{subaccountId}/locationId/{locationId}/column/{column}/start/{start}/end/{end}')
  /// Get one column in this tab for a given location.
  Future<List<Map<String, String>>> apiGetColumnTab1 (String accountId,
      String subaccountId,
      int locationId, String column, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    Stream data = _getData1(accountId, subaccountId, locationId, column, startDate, endDate);
    List out = [];
    List keys = ['hourBeginning', 'version', column];
    await for (Map e in data) {
      for (int i=0; i<e['hourBeginning'].length; i++){
        out.add(new Map.fromIterables(keys, [
          new TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          new TZDateTime.from(e['version'], _location).toString(),
          e[column][i]
        ]));
      }
    }
    return out;
  }


  /// Extract data for tab 0
  /// returns one element for each day
  Stream _getData0(String account,
      int locationId, String column, Date startDate, Date endDate) {
    List pipeline = [];
    pipeline.add({
      '\$match': {
        'account': {'\$eq': account},
        'tab': {'\$eq': 0},
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
      'version': 1,
      '${column}': 1,
    }});
    return coll.aggregateToStream(pipeline);
  }


  /// Extract data for tab 1
  /// returns one element for each day
  Stream _getData1(String accountId,
      String subaccountId, int locationId, String column, Date startDate, Date endDate) {
    List pipeline = [];
    pipeline.add({
      '\$match': {
        'account': {'\$eq': accountId},
        'tab': {'\$eq': 1},
        'Subaccount ID': {'\$eq': subaccountId},
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
      'version': 1,
      '${column}': 1,
    }});
    return coll.aggregateToStream(pipeline);
  }
}
