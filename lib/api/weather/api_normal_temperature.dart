library api.weather.normal_temperature;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiNormalTemperature {
  late DbCollection coll;
  String collectionName = 'normal_temperature';

  ApiNormalTemperature(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/airports', (Request request) async {
      var res = await allAirports();
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/airport/<airport>', (Request request, String type) async {
      var res = await getAirport(type);
      return Response.ok(json.encode(res), headers: headers);
    });

    return router;
  }

  Future<List<String>> allAirports() async {
    var aux = await coll.distinct('airportCode');
    return (aux['values'] as List).cast<String>();
  }

  /// a 3 digit code for US ones, 4 digit for international ones
  Future<List<Map<String, dynamic>>> getAirport(String airportCode) async {
    var query = where
      ..eq('airportCode', airportCode.toUpperCase())
      ..excludeFields(['_id', 'airportCode', 'asOfDate']);
    return coll.find(query).toList();
  }
}
