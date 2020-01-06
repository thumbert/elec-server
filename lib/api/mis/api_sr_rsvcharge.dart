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
  String collectionName = 'sr_rsvcharge';

  SrRsvCharge(Db db) {
    coll = db.collection(collectionName);
  }


  /// Get all data in tab 0
  @ApiMethod(path: 'accountId/tab/0/{accountId}/start/{start}/end/{end}')
  Future<ApiResponse> apiGetTab0(
      String accountId, String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 0)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab']);

    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }


  @ApiMethod(
      path:
          'accountId/{accountId}/tab/6/subaccountId/{subaccountId}/start/{start}/end/{end}')
  Future<ApiResponse> apiGetTab6(
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

  @ApiMethod(
      path:
      'accountId/{accountId}/tab/6/subaccountId/{subaccountId}/start/{start}/end/{end}/settlement/{settlement}')
  Future<ApiResponse> apiGetTab6Settlement(
      String accountId, String subaccountId, String start, String end, int settlement) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 6)
      ..eq('Subaccount ID', subaccountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    var data = await coll.find(query).toList();

    var grp = groupBy(data, (e) => Tuple2(e['Product Type'], e['Load Zone ID']));
    var out = <Map<String,dynamic>>[];
    for (var entry in grp.entries) {
      out.addAll(getNthSettlement(entry.value, n: settlement, group: 'date'));
    }
    return ApiResponse()..result = json.encode(out);
  }


  /// Get all data in tab 7
  @ApiMethod(
      path:
          'accountId/{accountId}/tab/7/subaccountId/{subaccountId}/start/{start}/end/{end}')
  Future<ApiResponse> apiGetTab7(
      String accountId, String subaccountId, String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 7)
      ..eq('Subaccount ID', subaccountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }

  @ApiMethod(
      path:
      'accountId/{accountId}/tab/7/subaccountId/{subaccountId}/start/{start}/end/{end}/settlement/{settlement}')
  Future<ApiResponse> apiGetTab7Settlement(
      String accountId, String subaccountId, String start, String end, int settlement) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 7)
      ..eq('Subaccount ID', subaccountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    var data = await coll.find(query).toList();

    var grp = groupBy(data, (e) => Tuple2(e['Product Type'], e['Load Zone ID']));
    var out = <Map<String,dynamic>>[];
    for (var entry in grp.entries) {
      out.addAll(getNthSettlement(entry.value, n: settlement, group: 'date'));
    }
    return ApiResponse()..result = json.encode(out);
  }


}
