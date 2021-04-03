library api.mis.sr_regsummary;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

// @ApiClass(name: 'sr_regsummary', version: 'v1')
class SrRegSummary {
  DbCollection coll;
  String collectionName = 'sr_regsummary';

  SrRegSummary(Db db) {
    coll = db.collection(collectionName);
  }

  /// http://localhost:8080/sr_regsummary/v1/account/0000523477/start/20170101/end/20170101
  // @ApiMethod(path: 'accountId/{accountId}/start/{start}/end/{end}')
  /// Get all data in tab 0 for a given location.
  Future<ApiResponse> apiGetTab0 (String accountId,
      String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getData(accountId, null, null, startDate, endDate);
    return ApiResponse()..result = json.encode(data);
  }


  // @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/start/{start}/end/{end}')
  /// Get all data in tab 1 for all locations.
  Future<ApiResponse> apiGetTab1 (String accountId,
      String subaccountId, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getData(accountId, subaccountId, null, startDate, endDate);
    return ApiResponse()..result = json.encode(data);
  }


  // @ApiMethod(
  //     path: 'accountId/{accountId}/column/{columnName}/start/{start}/end/{end}')
  /// Get one location, one column for the account.
  Future<ApiResponse> apiGetTab0ByLocationColumn (String accountId,
      String columnName, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getData(accountId, null, columnName, startDate, endDate);
    return ApiResponse()..result = json.encode(data);
  }


  // @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/column/{columnName}/start/{start}/end/{end}')
  /// Get all data for a subaccount for a given location, one column.
  Future<ApiResponse> apiGetTab1ByLocationColumn (String accountId,
      String subaccountId, String columnName, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getData(accountId, subaccountId, columnName, startDate, endDate);
    return ApiResponse()..result = json.encode(data);
  }

  /// Extract data from the collection
  /// returns one element for each day
  /// If [subaccountId] is [null] return data from tab 0 (the aggregated data)
  /// If [column] is [null] return all columns
  Future<List<Map<String,dynamic>>> getData(String account, String subaccountId,
      String column, Date startDate, Date endDate) async {
    var excludeFields = <String>['_id', 'account', 'tab'];

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

    if (column == null) {
      query.excludeFields(excludeFields);
    } else {
      query.excludeFields(['_id']);
      query.fields(['date', 'version', column]);
    }
    return coll.find(query).toList();
  }

}
