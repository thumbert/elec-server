library api.cme.api_cme;

import 'dart:async';
import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiCmeMarks {
  ApiCmeMarks(Db db) {
    coll = db.collection(collectionName);
  }

  late DbCollection coll;
  final String collectionName = 'settlements';

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/price/curvenames/asofdate/<asofdate>', (Request request, String asofdate) async {
      var res = await allCurveIds(asofdate);
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/price/curvename/<curvename>/asofdate/<asofdate>',
            (Request request, String curvename, String asofdate) async {
          var res = await getPrice(curvename, asofdate);
          return Response.ok(json.encode(res), headers: headers);
        });

    return router;
  }

  /// Return the list of curveIds sorted.
  Future<List<String>> allCurveIds(String asOfDate) async {
    var query = where
      ..eq('fromDate', asOfDate)
      ..fields(['curveId'])
      ..excludeFields(['_id']);
    var aux = await coll.find(query).map((e) => e['curveId'] as String).toList();
    return aux..sort();
  }

  Future<Map<String, dynamic>> getPrice(String curveId, String asOfDate) async {
    var query = where
      ..eq('curveId', curveId.toUpperCase())
      ..eq('fromDate', asOfDate)
      ..fields(['terms', 'values'])
      ..excludeFields(['_id']);
    return await coll.findOne(query) ?? <String,dynamic>{};
  }
}
