library api.other.curve_ids;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:elec_server/src/db/marks/curve_attributes.dart' as ca;

@ApiClass(name: 'curve_ids', version: 'v1')
class CurveIds {
  mongo.Db db;
  mongo.DbCollection coll;
  Map<String, Map<String, dynamic>> curveDefinitions;
  List<Map<String, dynamic>> compositeCurves;

  CurveIds(this.db) {
    coll = db.collection('curve_ids');
  }

  /// Get all the existing curve ids in the database, sorted
  @ApiMethod(path: 'all')
  Future<List<String>> getCurveIds() async {
    var aux = await coll.distinct('curveId');
    var res = <String>[...aux['values']];
    return res..sort();
  }

  /// Get all the unique regions, sorted
  @ApiMethod(path: 'regions')
  Future<List<String>> getRegions() async {
    var aux = await coll.distinct('region');
    var res = <String>[...aux['values']];
    return res..sort();
  }

  /// Get all the serviceTypes for one region, sorted
  @ApiMethod(path: 'region/{region}/serviceTypes')
  Future<List<String>> getServiceTypesForRegion(String region) async {
    var pipeline = [
      {
        '\$match': {
          'region': {'\$eq': region},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'serviceType': 1,
        }
      },
      {
        '\$sort': {'serviceType': 1},
      },
    ];
    return await coll
        .aggregateToStream(pipeline)
        .map((e) => e['serviceType'] as String)
        .toList();
  }

  @ApiMethod(path: 'region/{region}/serviceType/{serviceType}')
  Future<ApiResponse> getCurveIdsForRegionServiceType(String region,
      String serviceType) async {
    var pipeline = [
      {
        '\$match': {
          'region': {'\$eq': region},
          'serviceType': {'\$eq': serviceType},
        }
      },
      {
        '\$project': {
          '_id': 0,
        }
      },
    ];
    var aux = await coll.aggregateToStream(pipeline);
//        .toList();
    return ApiResponse()..result = json.encode(aux);
  }



  /// Get all the curveIds that match a given string pattern.
  /// For example all curves that have 'da' or 'lmp' in the curveId.
  @ApiMethod(path: 'curveIds/pattern/{pattern}')
  Future<List<String>> getCurveIdsContaining(String pattern) async {
    var aux = await coll.distinct('curveId');
    var res = <String>[
      ...(aux['values'] as List).where((e) => e.contains(pattern)),
    ];
    return res..sort();
  }




  Future<Map<String,dynamic>> _getForwardCurve(
      String asOfDate, String curveId) async {
    var pipeline = [
      {
        '\$match': {
          'curveId': {'\$eq': curveId},
          'fromDate': {'\$lte': Date.parse(asOfDate).toString()},
        }
      },
      {
        '\$sort': {'fromDate': -1},
      },
      {
        '\$limit': 1,
      },
      {
        '\$project': {
          '_id': 0,
          'fromDate': 0,
          'curveId': 0,
        }
      },
    ];
    var aux = await coll.aggregateToStream(pipeline).toList();
    return aux.first;
  }



}
