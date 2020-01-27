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

  /// Get all the existing curve ids in the database, sorted
  @ApiMethod(path: 'curveIds')
  Future<List<String>> getCurveIds() async {
    var aux = await coll.distinct('curveId');
    return (aux['values'] as List).cast<String>();
  }

  /// Get all the curveIds that match a given pattern.
  @ApiMethod(path: 'curveIds/pattern/{pattern}')
  Future<List<String>> getCurveIdsContaining(String pattern) async {
    var aux = await coll.distinct('curveId');
    var res = (aux['values'] as List).where((e) => e.contains(pattern));
    return res.toList().cast<String>();
  }

  /// TODO:

  /// Get all the curves that were marked on a given asOfDate
//  @ApiMethod(path: 'curveIds/asOfDate/{asOfDate}')

  /// Get all the days marked for one curveId
  /// Get the last entry for a given curveId
  /// Get the last two entries for a given curveId
  /// Get the forward prices for one curveId for two asOfDates

  /// Deal with spreads to hubs or composite curves (addition and multiplication).

  /// Get the forward curve as of a given date.
  @ApiMethod(path: 'asOfDate/{asOfDate}/curveId/{curveId}')
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

  /// Return only this bucket
  @ApiMethod(path: 'asOfDate/{asOfDate}/curveId/{curveId}/bucket/{bucket}')
  Future<ApiResponse> getForwardCurveForBucket(
      String asOfDate, String curveId, String bucket) async {
    var query = where
      ..gte('date', Date.parse(asOfDate).toString())
      ..eq('curveId', curveId)
      ..fields(['months', bucket]);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  Future<List<String>> getAsOfDates() async {
    var res = await coll.distinct('asOfDate');
    return (res['values'] as List).cast<String>();
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
