library api.nyiso.bingingconstraints;

import 'dart:async';
import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class BindingConstraints {
  late DbCollection coll;
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
      var aux = await apiGetBindingConstraintsForName(
          market, constraintName, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Return a List of elements in this form:
  /// ```
  /// {
  ///   'limitingFacility': 'CENTRAL EAST - VC',
  ///   'hours': [
  ///     {
  ///       'hourBeginning': '2019-01-01T18:00:00.000-0505',
  ///       'contingency': 'BASE CASE',
  ///       'cost': 0.02,
  ///     }, ...
  ///   ]
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> apiGetDaBindingConstraintsByDay(
      String start, String end) async {
    var query = where
      ..eq('market', 'DA')
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'date', 'market']);
    var aux = await coll.find(query).toList();
    for (var x in aux) {
      for (var e in x['hours']) {
        e['hourBeginning'] =
            TZDateTime.from(e['hourBeginning'] as DateTime, NewYorkIso.location)
                .toIso8601String();
      }
    }
    return aux;
  }

  /// Return a List of elements like this:
  /// ```
  /// {
  ///   'hourBeginning': '2019-01-01T18:00:00.000-0505',
  ///   'contingency': 'BASE CASE',
  ///   'cost': 0.02,
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> apiGetBindingConstraintsForName(
      String market, String constraintName, String start, String end) async {
    var query = where
      ..eq('market', market.toUpperCase())
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..eq('limitingFacility', constraintName)
      ..excludeFields(['_id', 'date', 'market', 'limitingFacility']);
    var aux = await coll.find(query).toList();
    var out = <Map<String, dynamic>>[];
    for (var x in aux) {
      for (var e in x['hours']) {
        e['hourBeginning'] =
            TZDateTime.from(e['hourBeginning'] as DateTime, NewYorkIso.location)
                .toIso8601String();
        out.add(e);
      }
    }
    return out;
  }
}
