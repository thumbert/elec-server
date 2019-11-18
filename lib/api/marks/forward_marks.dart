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
    coll = db.collection('forward_marks');
  }

  @ApiMethod(path: 'asOfDate/{asOfDate}/curveId/{curveId}')
  /// Get the forward curve
  Future<ApiResponse> getForwardCurve(String asOfDate, String curveId) async {
    var pipeline = [
      {
        '\$match': {
          'id': {'\$eq': curveId},
          'day': {'\$lte': Date.parse(asOfDate).toString()},
        }
      },
      {
        '\$sort': {'day': -1},
      },
      {
        '\$limit': 1,
      },
    ];
    var aux = await coll.aggregateToStream(pipeline).toList();
    return ApiResponse()..result = json.encode(aux.first);
  }

  @ApiMethod(path: 'asOfDate/{asOfDate}/curveId/{curveId}/bucket/{bucket}')
  /// Return only this bucket
  Future<ApiResponse> getForwardCurveForBucket(String asOfDate, String curveId,
      String bucket) async {
    var query = where
      ..gte('date', Date.parse(asOfDate).toString())
      ..eq('curveId', curveId)
      ..fields(['months', bucket]);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  Future<List<String>> getAsOfDates() async {
    var res = await coll.distinct('asOfDate');
    return res.values.toList().cast<String>() ;
  }

//  @ApiMethod(path: 'asOfDate/{asOfDate}/curveId/{curveId}/bucket/{bucket}')
//  /// TODO:
//  Future<ApiResponse> getHistoricalValueForTermBucket(String asOfDate,
//      String curveId, String term, String bucket) async {
//    var query = where
//      ..gte('date', Date.parse(asOfDate).toString())
//      ..eq('curveId', curveId)
//      ..fields(['months', bucket]);
//    var res = await coll.find(query).toList();
//    return ApiResponse()..result = json.encode(res);
//  }



  // TODO: return only one bucket, & return only a month,bucket historically



}


