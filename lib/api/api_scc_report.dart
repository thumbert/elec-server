library api.scc_report;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';
import '../src/utils/api_response.dart';


@ApiClass(name: 'scc_report', version: 'v1')
class SccReport {
  DbCollection coll;
  String collectionName = 'scc_report';

  SccReport(Db db) {
    coll = db.collection(collectionName);
  }

  @ApiMethod(path: 'month/{month}')
  Future<ApiResponse> getSccReportByMonth(String month) async {
    var yyyymm = month.replaceAll('-', '');
    if (yyyymm.length != 6)
      throw ArgumentError('Invalid month format $month');
    var mon = Month(int.parse(yyyymm.substring(0,4)),
        int.parse(yyyymm.substring(4)));

    SelectorBuilder query = where;
    query = query.eq('month', mon.toIso8601String());
    query = query.excludeFields(['_id', 'month']);
    var res = await coll.find(query).toList();
    return new ApiResponse()..result = json.encode(res);
  }

  @ApiMethod(path: 'assetId/{assetId}')
  Future<ApiResponse> getSccReportByAssetId(int assetId) async {
    SelectorBuilder query = where;
    query = query.eq('Asset ID', assetId);
    query = query.excludeFields(['_id']);
    var res = await coll.find(query).toList();
    return new ApiResponse()..result = json.encode(res);
  }

  @ApiMethod(path: 'months')
  Future<ApiResponse> getMonths() async {
    var res = await coll.distinct('month');
    return new ApiResponse()..result = json.encode(res['values']);
  }



}

