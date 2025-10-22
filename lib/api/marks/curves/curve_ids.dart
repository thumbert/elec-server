import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class CurveIds {
  mongo.Db db;
  late mongo.DbCollection coll;
  Map<String, Map<String, dynamic>>? curveDefinitions;
  List<Map<String, dynamic>>? compositeCurves;

  CurveIds(this.db) {
    coll = db.collection('curve_ids');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all the existing curve ids in the database, sorted
    router.get('/curveIds', (Request request) async {
      var aux = await coll.distinct('curveId');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    /// Get all the existing curve ids in the database that match the pattern,
    /// sorted
    router.get('/curveIds/pattern/<pattern>',
        (Request request, String pattern) async {
      var aux = await curveIdsWithPattern(pattern);
      aux.sort();
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get all the unique commodities, sorted
    router.get('/commodities', (Request request) async {
      var aux = await coll.distinct('commodity');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    /// Get all the unique regions for a given commodity (e.g. electricity),
    /// sorted
    router.get('/commodity/<commodity>/regions',
        (Request request, String commodity) async {
      var aux = await getRegions(commodity);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get all the unique regions for a given commodity and region, sorted
    /// For example (electricity, isone)
    router.get('/commodity/<commodity>/region/<region>/serviceTypes',
        (Request request, String commodity, String region) async {
      var aux = await getServiceTypes(commodity, region);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get the unique document associated with this curveId
    router.get('/data/curveId/<curveId>',
        (Request request, String curveId) async {
      var aux = await getCurveId(curveId);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get the documents associated with these curveIds.  Multiple curveIds are
    /// separated by |.
    router.get('/data/curveIds/<curveIds>',
        (Request request, String curveIds) async {
      curveIds = Uri.decodeFull(curveIds);
      var aux = await getCurveIds(curveIds);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get all the documents for a given commodity, region and serviceType
    router.get(
        '/data/commodity/<commodity>/region/<region>/serviceType/<serviceType>',
        (Request request, String commodity, String region,
            String serviceType) async {
      var aux = await getDocuments(commodity, region, serviceType);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Get all the existing curve ids in the database that match the pattern,
  /// sorted
  Future<List<String?>> curveIdsWithPattern(String pattern) async {
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
        .map((e) => e['curveId'] as String?)
        .toList();
  }

  /// Get the document associated with this curveId
  Future<Map<String, dynamic>?> getCurveId(String curveId) async {
    var query = mongo.where
      ..eq('curveId', curveId)
      ..excludeFields(['_id']);
    return await coll.findOne(query);
  }

  /// Get the documents associated with these curveIds.  Multiple curveIds are
  /// separated by |.
  Future<List<Map<String, dynamic>>> getCurveIds(String curveIds) async {
    var _ids = curveIds.split('|');
    var query = mongo.where
      ..oneFrom('curveId', _ids)
      ..excludeFields(['_id']);
    return await coll.find(query).toList();
  }

  /// For a given commodity, get all the unique regions, sorted
  Future<List<String?>> getRegions(String commodity) async {
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
        .map((e) => e['region'] as String?)
        .toList();
  }

  /// For a given commodity and region, get all the serviceTypes, sorted
  Future<List<String?>> getServiceTypes(String commodity, String region) async {
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
        .map((e) => e['serviceType'] as String?)
        .toList();
  }

  /// Get all the electricity documents for a given region and serviceType
  Future<List<Map<String, dynamic>>> getDocuments(
      String commodity, String region, String serviceType) async {
    var pipeline = [
      {
        '\$match': {
          'commodity': {'\$eq': commodity},
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
    var out = await coll.aggregateToStream(pipeline).toList();
    return out;
  }
}
