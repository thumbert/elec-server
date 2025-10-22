import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiIsoneBtmSolar {
  ApiIsoneBtmSolar(Db db) {
    coll = db.collection('hourly_btm_solar');
  }
  late final DbCollection coll;

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/zones', (Request request) async {
      var aux = await coll.distinct('zone');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/zone/<zone>/start/<start>/end/<end>',
        (Request request, String zone, String start, String end) async {
      var aux = await getData(zone, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> getData(
      String zone, String start, String end) async {
    var query = where
      ..eq('zone', zone.toUpperCase())
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..sortBy('date')
      ..excludeFields(['_id', 'zone']);
    return coll.find(query).toList();
  }
}
