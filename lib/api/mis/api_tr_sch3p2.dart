library api.tr_sch3p2;

import 'dart:async';
import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';

@ApiClass(name: 'tr_sch3p2', version: 'v1')
class TrSch3p2 {
  DbCollection coll;
  Location location;
  var collectionName = 'tr_sch3p2';

  TrSch3p2(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  /// [start], [end] are months in yyyy-mm format.  Return all account,
  /// subaccount data for all settlements.
  @ApiMethod(path: 'accountId/{accountId}/start/{start}/end/{end}')
  Future<ApiResponse> dataForAccount(
      String accountId, String start, String end) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 0)
      ..gte('month', startMonth)
      ..lte('month', endMonth)
      ..excludeFields(['_id', 'account', 'tab']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  /// [start], [end] are months in yyyy-mm format.  Return all
  /// subaccount data for all settlements.
  @ApiMethod(
      path:
          'accountId/{accountId}/subaccountId/{subaccountId}/start/{start}/end/{end}')
  Future<ApiResponse> dataForSubaccount(
      String accountId, String subaccountId, String start, String end) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();
    var query = where
      ..eq('account', accountId)
      ..eq('Subaccount ID', subaccountId)
      ..eq('tab', 1)
      ..gte('month', startMonth)
      ..lte('month', endMonth)
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }
}
