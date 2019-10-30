library api.sd_rtncpcpymt;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'sd_rtncpcpymt', version: 'v1')
class SdRtNcpcPymt {
  DbCollection coll;
  Location location;
  var collectionName = 'sd_rtncpcpymt';

  SdRtNcpcPymt(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
  }

  @ApiMethod(path: 'accountId/{accountId}/start/{start}/end/{end}')
  Future<ApiResponse> data0(String accountId, String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  @ApiMethod(path: 'accountId/{accountId}/assetId/{assetId}/start/{start}/end/{end}')
  Future<ApiResponse> data0ForAsset(String accountId, int assetId,
      String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..gte('date', start)
      ..lte('date', end)
      ..eq('Asset ID', assetId)
      ..excludeFields(['_id', 'account']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/details/start/{start}/end/{end}')
  /// Get the details for all assets, all versions
  Future<ApiResponse> data2CreditDetails(String accountId, String subaccountId,
      String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 2)
      ..eq('Subaccount ID', subaccountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..fields(['date', 'version', 'Asset ID', 'NCPC Commitment Credit Type',
        'Participant Share of Real-Time NCPC Credit']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }



}
