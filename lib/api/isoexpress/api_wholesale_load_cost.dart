library api.isoexpress.api_wholesale_load_cost;

import 'dart:convert';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'rt_load', version: 'v1')
class WholesaleLoadCost {
  DbCollection coll;
  String collectionName = 'wholesale_load_cost';

  /// the only report published by the ISONE where you find zonal RT load
  WholesaleLoadCost(Db db) {
    coll = db.collection(collectionName);
  }

  /// http://localhost:8080/rt_load/v1/ptid/4004/start/20190101/end/20190131
  @ApiMethod(path: 'isone/load_zone/ptid/{ptid}/start/{start}/end/{end}')
  Future<ApiResponse> apiGetZonalRtLoad(
      int ptid, String start, String end) async {
    var query = where
      .eq('ptid', ptid)
      .gte('date', Date.parse(start).toString())
      .lte('date', Date.parse(end).toString())
      .excludeFields(['_id'])
      .fields(['date', 'rtLoad']);
    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }

  /// http://localhost:8080/rt_load/v1/pool/start/20190101/end/20190131
  @ApiMethod(path: 'isone/pool/start/{start}/end/{end}')
  Future<ApiResponse> apiGetPoolRtLoad(
      int ptid, String start, String end) async {
    var query = where
      .eq('ptid', 4000)
      .gte('date', Date.parse(start).toString())
      .lte('date', Date.parse(end).toString())
      .excludeFields(['_id'])
      .fields(['date', 'rtLoad']);
    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }



}
