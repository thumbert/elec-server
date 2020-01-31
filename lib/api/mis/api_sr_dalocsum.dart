library api.mis.sr_dalocsum;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:tuple/tuple.dart';


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

  @ApiMethod(
      path:
      'daenergy_settlement/daily/accountId/{accountId}/start/{start}/end/{end}/settlement/{settlement}')
  Future<ApiResponse> dailyDaSettlementForAccount(
      String accountId, String start, String end, int settlement) async {
    var startDate = Date.parse(start).toString();
    var endDate = Date.parse(end).toString();
    var data = await _getDailyData(
        accountId, null, startDate, endDate, settlement,
        columns: [
          'Day Ahead Energy Charge / Credit',
          'Day Ahead Congestion Charge / Credit',
          'Day Ahead Loss Charge / Credit',
        ]);
    return ApiResponse()..result = json.encode(data..forEach((e) => e.remove('version')));
  }


  @ApiMethod(
      path:
      'rtenergy_settlement/daily/accountId/{accountId}/subaccountId/{subaccountId}/start/{start}/end/{end}/settlement/{settlement}')
  Future<ApiResponse> dailyDaSettlementForSubaccount(
      String accountId,
      String subaccountId,
      String start,
      String end,
      int settlement) async {
    var startDate = Date.parse(start).toString();
    var endDate = Date.parse(end).toString();
    var data = await _getDailyData(
        accountId, subaccountId, startDate, endDate, settlement,
        columns: [
          'Day Ahead Energy Charge / Credit',
          'Day Ahead Congestion Charge / Credit',
          'Day Ahead Loss Charge / Credit',
        ]);
    return ApiResponse()..result = json.encode(data..forEach((e) => e.remove('version')));
  }



  /// Get daily total for a subaccount for a given location, one settlement.
  Future<List<Map<String, dynamic>>> _getDailyData(String accountId,
      String subaccountId, String startDate, String endDate, int settlement,
      {List<String> columns}) async {
    var pipeline = [
      {
        '\$match': {
          'account': {'\$eq': accountId},
          'tab': {'\$eq': subaccountId == null ? 0 : 1},
          if (subaccountId != null) 'Subaccount ID': {'\$eq': subaccountId},
          'date': {
            '\$gte': startDate,
            '\$lte': endDate,
          },
        },
      },
      {
        '\$group': {
          '_id': {
            'date': '\$date',
            'version': '\$version',
            'Location ID': '\$Location ID',
            ...{
              for (var column in columns) column: {'\$sum': '\$$column'}
            },
          }
        },
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          'version': '\$_id.version',
          'Location ID': '\$_id.Location ID',
          ...{for (var column in columns) column: '\$_id.$column'},
        },
      },
      {
        '\$sort': {
          'date': 1,
        }
      },
    ];
    var data = await coll.aggregateToStream(pipeline).toList();
    var aux = getNthSettlement(data, (e) => Tuple2(e['date'], e['Location ID']), n: settlement);
    return aux;
  }




  /// http://localhost:8080/sr_rtlocsum/v1/account/0000523477/start/20170101/end/20170101
  @ApiMethod(path: 'accountId/{accountId}/start/{start}/end/{end}')
  /// Get all data in tab 0 for a given location.
  Future<ApiResponse> apiGetTab0 (String accountId,
      String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getData(accountId, null, null, null, startDate, endDate);
    var aux = _processStream(data);
    return ApiResponse()..result = json.encode(aux);
  }


  @ApiMethod(
      path: 'accountId/{accountId}/locationId/{locationId}/start/{start}/end/{end}')
  /// Get all data (all locations) for the account.
  Future<ApiResponse> apiGetTab0ByLocation (String accountId,
      int locationId, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getData(accountId, null, locationId, null, startDate, endDate);
    var aux = _processStream(data);
    return ApiResponse()..result = json.encode(aux);
  }


  @ApiMethod(
      path: 'accountId/{accountId}/locationId/{locationId}/column/{columnName}/start/{start}/end/{end}')
  /// Get one location, one column for the account.
  Future<ApiResponse> apiGetTab0ByLocationColumn (String accountId,
      int locationId, String columnName, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getData(accountId, null, locationId, columnName, startDate, endDate);
    var aux = _processStream(data);
    return ApiResponse()..result = json.encode(aux);
  }

  
  @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/start/{start}/end/{end}')
  /// Get all data in tab 1 for all locations.
  Future<ApiResponse> apiGetTab1 (String accountId,
      String subaccountId, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getData(accountId, subaccountId, null, null, startDate, endDate);
    var aux = _processStream(data);
    return ApiResponse()..result = json.encode(aux);
  }


  @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/locationId/{locationId}/start/{start}/end/{end}')
  /// Get all data in tab 1 for a given location.
  Future<ApiResponse> apiGetTab1ByLocation (String accountId,
      String subaccountId, int locationId, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getData(accountId, subaccountId, locationId, null, startDate, endDate);
    var aux = _processStream(data, hasLocationId: false);
    return ApiResponse()..result = json.encode(aux);
  }


  @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/locationId/{locationId}/column/{columnName}/start/{start}/end/{end}')
  /// Get all data for a subaccount for a given location, one column.
  Future<ApiResponse> apiGetTab1ByLocationColumn (String accountId,
      String subaccountId, int locationId, String columnName, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var data = await getData(accountId, subaccountId, locationId, columnName, startDate, endDate);
    var aux = _processStream(data, hasLocationId: false);
    return ApiResponse()..result = json.encode(aux);
  }


  List<Map<String,dynamic>> _processStream(List<Map<String,dynamic>> data, {bool hasLocationId: true}) {
    var out = <Map<String,dynamic>>[];
    List<String> otherKeys;
    for (var e in data) {
      otherKeys ??= e.keys.toList()
        ..remove('hourBeginning')
        ..remove('version')
        ..remove('Location ID');
      for (int i=0; i<e['hourBeginning'].length; i++) {
        var aux = <String,dynamic>{
          'hourBeginning': TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          'version': TZDateTime.from(e['version'], _location).toString(),
        };
        if (hasLocationId) aux['Location ID'] = e['Location ID'];
        for (String key in otherKeys) {
          aux[key] = e[key][i];
        }
        out.add(aux);
      }
    }
    return out;
  }



  /// Extract data from the collection
  /// returns one element for each day
  /// If [subaccountId] is [null] return data from tab 0 (the aggregated data)
  /// If [locationId] is [null] return all locations
  /// If [column] is [null] return all columns
  Future<List<Map<String,dynamic>>> getData(String account, String subaccountId,
      int locationId, String column, Date startDate, Date endDate) async {
    var excludeFields = <String>['_id', 'account', 'tab', 'date'];

    var query = where;
    query.eq('account', account);
    if (subaccountId == null) {
      query.eq('tab', 0);
    } else {
      query.eq('tab', 1);
      query.eq('Subaccount ID', subaccountId);
      excludeFields.add('Subaccount ID');
    }
    query.gte('date', startDate.toString());
    query.lte('date', endDate.toString());
    if (locationId != null)
      query.eq('Location ID', locationId);

    if (column == null) {
      query.excludeFields(excludeFields);
    } else {
      query.excludeFields(['_id']);
      query.fields(['hourBeginning', 'version', column]);
    }
    return coll.find(query).toList();
  }


  /// Extract data from tab 0
  /// returns one element for each day
  /// If [subaccountId] is [null] return data from tab 0 (the aggregated data)
  /// If [locationId] is [null] return all locations
  /// If [column] is [null] return all columns
  Stream _getData(String account, String subaccountId,
      int locationId, String column, Date startDate, Date endDate) {
    List pipeline = [];
    Map match = {'account': {'\$eq': account}};
    if (subaccountId == null) {
      match['tab'] = {'\$eq': 0};
    } else {
      match['tab'] = {'\$eq': 1};
      match['Subaccount ID'] = {'\$eq': subaccountId};
    }
    match['date'] = {
        '\$gte': startDate.toString(),
        '\$lte': endDate.toString(),
    };
    if (locationId != null) match['Location ID']= {'\$eq': locationId};
    pipeline.add({'\$match': match});
    Map project = {
      '_id': 0,
      'account': 0,
      'tab': 0,
      'date': 0,
    };
    if (subaccountId != null) project['Subaccount ID'] = 0;
    pipeline.add({'\$project': project});
    
    if (column != null) {
      /// add another projection to get only this column
      pipeline.add({'\$project': {
        'hourBeginning': 1,
        'version': 1,
        column: 1,
      }});
    }
    return coll.aggregateToStream(pipeline);
  }

  
}



