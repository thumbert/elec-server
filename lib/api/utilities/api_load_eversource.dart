library api.utilities.api_load_eversource;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiLoadEversource {
  DbCollection coll1;
  var location;

  ApiLoadEversource(Db db) {
    coll1 = db.collection('load_ct');
    location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/zone/ct/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await ctLoad(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// return the hourly historical load for ct by load class, including competitive
  /// supply.
  Future<List<Map<String, dynamic>>> ctLoad(String start, String end) async {
    var query = where;
    query = query.gte('date', Date.parse(start).toString());
    query = query.lte('date', Date.parse(end).toString());
    query = query.excludeFields(['_id']);
    return coll1.find(query).toList();
  }
}
