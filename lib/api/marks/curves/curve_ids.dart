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
  @ApiMethod(path: 'curveIds')
  Future<List<String>> curveIds() async {
    var aux = await coll.distinct('curveId');
    var res = <String>[...aux['values']];
    return res..sort();
  }

  /// Get all the existing curve ids in the database that match the pattern,
  /// sorted
  @ApiMethod(path: 'curveIds/pattern/{pattern}')
  Future<List<String>> curveIdsWithPattern(String pattern) async {
    var pipeline = [
      {
        '\$match': {
          'curveId': {'\$regex': pattern},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'curveId': '\$curveId',
        }
      },
      {
        '\$sort': {'curveId': 1},
      },
    ];
    return await coll
        .aggregateToStream(pipeline)
        .map((e) => e['curveId'] as String)
        .toList();
  }


  /// Get the document associated with this curveId
  @ApiMethod(path: 'data/curveId/{curveId}')
  Future<ApiResponse> getCurveId(String curveId) async {
    var query = mongo.where
      ..eq('curveId', curveId)
      ..excludeFields(['_id']);
//    var aux = await coll.findOne({'curveId': curveId});
    var aux = await coll.findOne(query);
    return ApiResponse()..result = json.encode(aux);
  }

  /// Get the documents associated with these curveIds.  Multiple curveIds are
  /// separated by |.
  @ApiMethod(path: 'data/curveIds/{curveIds}')
  Future<ApiResponse> getCurveIds(String curveIds) async {
    var _ids = curveIds.split('|');
    var query = mongo.where
      ..oneFrom('curveId', _ids)
      ..excludeFields(['_id']);
    var aux = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(aux);
  }

  /// Get all the unique commodities, sorted
  @ApiMethod(path: 'commodities')
  Future<List<String>> getCommodities() async {
    var aux = await coll.distinct('commodity');
    var res = <String>[...aux['values']];
    return res..sort();
  }

  /// For a given commodity, get all the unique regions, sorted
  @ApiMethod(path: 'commodity/{commodity}/regions')
  Future<List<String>> getRegions(String commodity) async {
    var pipeline = [
      {
        '\$match': {
          'commodity': {'\$eq': commodity},
        }
      },
      {
        '\$group': {
          '_id': {'region': '\$region'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'region': '\$_id.region',
        }
      },
      {
        '\$sort': {'region': 1},
      },
    ];
    return await coll
        .aggregateToStream(pipeline)
        .map((e) => e['region'] as String)
        .toList();
  }

  /// For a given commodity and region, get all the serviceTypes, sorted
  @ApiMethod(path: 'commodity/{commodity}/region/{region}/serviceTypes')
  Future<List<String>> getServiceTypes(String commodity, String region) async {
    var pipeline = [
      {
        '\$match': {
          'commodity': {'\$eq': commodity},
          'region': {'\$eq': region},
        }
      },
      {
        '\$group': {
          '_id': {'serviceType': '\$serviceType'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'serviceType': '\$_id.serviceType',
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

  /// Get all the electricity documents for a given region and serviceType
  @ApiMethod(path: 'data/commodity/electricity/region/{region}/serviceType/{serviceType}')
  Future<ApiResponse> getElectricityDocuments(String region, String serviceType) async {
    var pipeline = [
      {
        '\$match': {
          'commodity': {'\$eq': 'electricity'},
          'region': {'\$eq': region},
          'serviceType': {'\$eq': serviceType},
        }
      },
      {
        '\$project': {
          '_id': 0,
        }
      },
      {
        '\$sort': {'curve': 1},
      },
    ];
    var out = await coll
        .aggregateToStream(pipeline)
        .toList();
    return ApiResponse()..result = json.encode(out);
  }




}
