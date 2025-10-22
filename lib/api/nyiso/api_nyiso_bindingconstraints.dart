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

    /// Get all the constraints between start/end date, hourly data
    router.get('/market/da/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await apiGetDaBindingConstraintsByDay(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/market/da/start/<start>/end/<end>/timeseries',
        (Request request, String start, String end) async {
      var aux = await apiGetDaBindingConstraintsHourlyCost(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get all the constraints between start/end date
    router.get('/market/da/start/<start>/end/<end>/dailycost',
        (Request request, String start, String end) async {
      var aux = await apiGetDaBindingConstraintsDailyCost(start, end);
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
      ..sortBy('date')
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
        '\$unwind': '\$hours',
      },
      {
        '\$group': {
          '_id': {
            'name': '\$limitingFacility',
            'hourBeginning': '\$hours.hourBeginning',
          },
          'cost': {'\$sum': '\$hours.cost'}, // sum over multiple contingencies
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

  /// Calculate the daily cost of a constraint.  Return a list in form
  /// ```
  /// {
  ///   'date': '2019-01-01',
  ///   'constraintName': 'CENTRAL EAST - VC',
  ///   'cost': 187.23,
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> apiGetDaBindingConstraintsDailyCost(
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
        '\$unwind': '\$hours',
      },
      {
        '\$group': {
          '_id': {
            'date': '\$date',
            'name': '\$limitingFacility',
          },
          'cost': {'\$sum': '\$hours.cost'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          'constraintName': '\$_id.name',
          'cost': '\$cost',
        }
      },
      {
        '\$sort': {
          'date': 1,
          // 'cost': -1,
        }
      }
    ];

    var res = await coll.aggregateToStream(pipeline).toList();
    return res;
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
