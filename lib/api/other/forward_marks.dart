library api.other.forward_marks;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';
import '../../src/utils/api_response.dart';

@ApiClass(name: 'forward_marks', version: 'v1')
class ForwardMarks {
  Db db;
  DbCollection coll;

  ForwardMarks(this.db) {
    coll = db.collection('monthly_marks');
  }

  @ApiMethod(path: 'asOfDate/{asOfDate}/curveId/{curveId}')
  /// Return all existing buckets
  Future<ApiResponse> getForwardCurve(String asOfDate, String curveId) async {
    var query = where
      ..gte('date', Date.parse(asOfDate).toString())
      ..eq('curveId', curveId)
      ..excludeFields(['_id', 'asOfDate', 'curveId']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  // TODO: return only one bucket, & return only a month,bucket historically



}


