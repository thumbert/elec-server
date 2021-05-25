library api.isone_bingingconstraints;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class BindingConstraints {
  late DbCollection coll;
  final Location _location = getLocation('America/New_York');
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'binding_constraints';

  BindingConstraints(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all the constraints between start/end date
    router.get('/market/da/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await apiGetDaBindingConstraintsByDay(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get the occurrences of one constraint between start/end
    router.get(
        '/market/<market>/constraintname/<constraintname>/start/<start>/end/<end>',
        (Request request, String market, String constraintName, String start,
            String end) async {
      constraintName = Uri.decodeComponent(constraintName);
      var aux = await apiGetBindingConstraintsByName(
          market, constraintName, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> apiGetDaBindingConstraintsByDay(
      String start, String end) async {
    var query = where;
    query = query.gte('date', Date.parse(start).toString());
    query = query.lte('date', Date.parse(end).toString());
    query = query.eq('market', 'DA');
    query = query.excludeFields(['_id', 'date', 'market']);
    var res = await coll.find(query).map((Map<String, Object?> e) {
      var start = TZDateTime.from(e['hourBeginning'] as DateTime, _location);
      e['hourBeginning'] = start.toString();
      return e;
    }).toList();
    return res;
  }

  Future<List<Map<String, dynamic>>> apiGetBindingConstraintsByName(
      String market, String constraintName, String start, String end) async {
    var query = where;
    query = query.gte('date', Date.parse(start).toString());
    query = query.lte('date', Date.parse(end).toString());
    query = query.eq('Constraint Name', constraintName);
    query = query.eq('market', market.toUpperCase());
    query = query.excludeFields(['_id', 'date', 'market']);
    var res = await coll.find(query).map((Map<String, Object?> e) {
      var start = TZDateTime.from(e['hourBeginning'] as DateTime, _location);
      e['hourBeginning'] = start.toString();
      return e;
    }).toList();
    return res;
  }
}
