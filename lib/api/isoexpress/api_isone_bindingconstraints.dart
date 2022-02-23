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

    /// Get all the constraints between start/end date, return timeseries
    router.get('/market/da/start/<start>/end/<end>/timeseries',
        (Request request, String start, String end) async {
      var aux = await apiGetDaBindingConstraintsHourlyCost(start, end);
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
    var query = where
      ..eq('market', 'DA')
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'date', 'market']);
    var aux = await coll.find(query).toList();
    var out = aux.map((e) => e['constraints'] as List).expand((constraints) {
      for (var constraint in constraints) {
        var start =
            TZDateTime.from(constraint['hourBeginning'] as DateTime, _location);
        constraint['hourBeginning'] = start.toString();
      }
      return constraints.cast<Map<String, dynamic>>();
    }).toList();
    return out;
  }

  Future<List<Map<String, dynamic>>> apiGetBindingConstraintsByName(
      String market, String constraintName, String start, String end) async {
    /// TODO: do it in Mongo
    var aux = await apiGetDaBindingConstraintsByDay(start, end);
    return aux.where((e) => e['Constraint Name'] == constraintName).toList();
  }

  /// Calculate the total hourly cost of a constraint.  Return a list in form
  /// ```
  /// {
  ///   'constraintName': 'CENTRAL EAST - VC',
  ///   'hourBeginning': <num>[...],  // millisSinceEpoch
  ///   'cost': <num>[187.23, ...],
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> apiGetDaBindingConstraintsHourlyCost(
      String start, String end) async {
    var pipeline = <Map<String, Object>>[
      {
        '\$match': {
          'date': {
            '\$lte': Date.parse(end).toString(),
            '\$gte': Date.parse(start).toString(),
          },
        }
      },
      {
        '\$unwind': '\$constraints',
      },
      {
        '\$group': {
          '_id': {
            'name': '\$constraints.Constraint Name',
            'hourBeginning': '\$constraints.hourBeginning',
          },
          'cost': {
            '\$sum': '\$constraints.Marginal Value'
          }, // sum over multiple contingencies
        }
      },
      {
        '\$project': {
          '_id': 0,
          'constraintName': '\$_id.name',
          'hourBeginning': '\$_id.hourBeginning',
          'cost': '\$cost',
        }
      },

      /// need to sort by
      {
        '\$sort': {
          'constraintName': 1,
          'hourBeginning': 1,
        }
      },

      /// group again by name, and collect into arrays
      {
        '\$group': {
          '_id': {
            'constraintName': '\$constraintName',
          },
          'hourBeginning': {'\$push': '\$hourBeginning'},
          'cost': {'\$push': '\$cost'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'constraintName': '\$_id.constraintName',
          'hourBeginning': '\$hourBeginning',
          'cost': '\$cost',
        }
      },
    ];

    var res = await coll.aggregateToStream(pipeline).map((e) {
      e['hourBeginning'] = (e['hourBeginning'] as List)
          .map((e) => e.millisecondsSinceEpoch)
          .toList();
      return e;
    }).toList();
    return res;
  }
}
