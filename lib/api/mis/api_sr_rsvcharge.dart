library api.mis.sr_rsvcharge;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:tuple/tuple.dart';

@ApiClass(name: 'sr_rsvcharge', version: 'v1')
class SrRsvCharge {
  DbCollection coll;
  final collectionName = 'sr_rsvcharge';

  SrRsvCharge(Db db) {
    coll = db.collection(collectionName);
  }

/// Get all data in tab 4, participant section
  @ApiMethod(path: 'charges/accountId/{accountId}/start/{start}/end/{end}')
  Future<ApiResponse> chargesAccount(
      String accountId, String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 4)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab']);

    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }

  /// Get all data in tab 4, participant section, one settlement
  @ApiMethod(path: 'charges/accountId/{accountId}/start/{start}/end/{end}/settlement/{settlement}')
  Future<ApiResponse> chargesAccountSettlement(
      String accountId, String start, String end, int settlement) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 4)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab']);

    var data = await coll.find(query).toList();
    var out = getNthSettlement(
        data, (e) => Tuple2(e['date'], e['Load Zone ID']),
        n: settlement);
    return ApiResponse()..result = json.encode(out);
  }

  /// tab 6, subaccount section, all settlements
  @ApiMethod(
      path:
          'charges/accountId/{accountId}/subaccountId/{subaccountId}/start/{start}/end/{end}')
  Future<ApiResponse> chargesSubaccount(
      String accountId, String subaccountId, String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 6)
      ..eq('Subaccount ID', subaccountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }

  /// tab 6, subaccount section
  @ApiMethod(
      path:
          'charges/accountId/{accountId}/subaccountId/{subaccountId}/start/{start}/end/{end}/settlement/{settlement}')
  Future<ApiResponse> chargesSubaccountSettlement(String accountId,
      String subaccountId, String start, String end, int settlement) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 6)
      ..eq('Subaccount ID', subaccountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    var data = await coll.find(query).toList();

    var out = getNthSettlement(
        data, (e) => Tuple2(e['date'], e['Load Zone ID']),
        n: settlement);
    return ApiResponse()..result = json.encode(out);
  }

}
