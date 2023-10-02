library api.ieso.api_ieso_rtgeneration;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:shelf_router/shelf_router.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';

class ApiIesoRtGeneration {
  ApiIesoRtGeneration(Db db) {
    coll = db.collection(collectionName);
  }

  late DbCollection coll;
  final String collectionName = 'rt_generation';

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all generators names
    router.get('/names', (Request request) async {
      var aux = await coll.distinct('name');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    /// Get all variables from one generator between a start/end date
    router.get('/name/<name>/start/<start>/end/<end>',
        (Request request, String name, String start, String end) async {
      var aux = await getAllVariablesForName(
          name, Date.parse(start).toString(), Date.parse(end).toString());
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get a variable from one generator between a start/end date
    router.get('/name/<name>/<variable>/start/<start>/end/<end>',
        (Request request, String name, String variable, String start,
            String end) async {
      var aux = await getVariableForName(name, variable.toLowerCase(),
          Date.parse(start).toString(), Date.parse(end).toString());
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get one generation by fuel type between a start/end date
    router.get('/fuel/<fuel>/<variable>/start/<start>/end/<end>',
        (Request request, String fuel, String variable, String start,
            String end) async {
      var aux = await getGenerationForFuel(fuel, variable.toLowerCase(),
          Date.parse(start).toString(), Date.parse(end).toString());
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> getVariableForName(
      String name, String variable, String startDate, String endDate) async {
    var query = where
      ..eq('name', name)
      ..gte('date', startDate)
      ..lte('date', endDate)
      ..fields(['date', variable])
      ..excludeFields(['_id']);
    return coll.find(query).toList();
  }

  Future<List<Map<String, dynamic>>> getAllVariablesForName(
      String name, String startDate, String endDate) async {
    var query = where
      ..eq('name', name)
      ..gte('date', startDate)
      ..lte('date', endDate)
      ..excludeFields(['_id', 'name', 'fuel']);
    return coll.find(query).toList();
  }

  Future<List<Map<String, dynamic>>> getGenerationForFuel(
      String fuel, String variable, String startDate, String endDate) async {
    var pipeline = <Map<String, Object>>[
      {
        '\$match': {
          'fuel': {
            '\$eq': fuel,
          },
          'date': {
            '\$lte': endDate,
            '\$gte': startDate,
          },
        }
      },
      {
        '\$project': {
          '_id': 0,
          'date': 1,
          'name': 1,
          variable: 1,
        }
      },
      {
        '\$unwind': {
          'path': '\$$variable',
          'includeArrayIndex': 'hour',
        }
      },
      {
        '\$group': {
          '_id': {
            'date': '\$date',
            'hour': '\$hour',
          },
          variable: {'\$sum': '\$$variable'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          'hour': '\$_id.hour',
          variable: '\$$variable',
        }
      },
      {
        '\$sort': {
          'date': 1,
          'hour': 1,
        }
      },
      {
        '\$group': {
          '_id': {
            'date': '\$date',
          },
          variable: {'\$push': '\$$variable'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          variable: '\$$variable',
        }
      },
      {
        '\$sort': {
          'date': 1,
        }
      },
    ];

    var res = await coll.aggregateToStream(pipeline).toList();
    return res;
  }
}
