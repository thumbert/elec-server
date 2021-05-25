library api.sd_rtncpcpymt;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

// @ApiClass(name: 'sd_rtncpcpymt', version: 'v1')
class SdRtNcpcPymt {
  late DbCollection coll;
  final Location location = getLocation('America/New_York');

  SdRtNcpcPymt(Db db) {
    coll = db.collection('sd_rtncpcpymt');
  }

  // @ApiMethod(path: 'accountId/{accountId}/start/{start}/end/{end}')
  Future<ApiResponse> data0(String accountId, String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 0)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  // @ApiMethod(path: 'accountId/{accountId}/assetId/{assetId}/start/{start}/end/{end}')
  Future<ApiResponse> data0ForAsset(String accountId, int assetId,
      String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 0)
      ..gte('date', start)
      ..lte('date', end)
      ..eq('Asset ID', assetId)
      ..excludeFields(['_id', 'account']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  // @ApiMethod(path: 'accountId/{accountId}/details/start/{start}/end/{end}')
  /// Get the ncpc credit details for all assets, all versions of the report
  Future<ApiResponse> data2CreditDetails(String accountId, String subaccountId,
      String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 2)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..fields(['date', 'version', 'Asset ID', 'NCPC Commitment Credit Type',
        'Participant Share of Real-Time NCPC Credit']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }



}
