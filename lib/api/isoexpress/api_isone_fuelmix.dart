import 'dart:async';
import 'dart:convert';
import 'package:timezone/timezone.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiIsoneFuelMix {
  late DbCollection coll;
  String collectionName = 'fuel_mix';
  Location location = getLocation('America/New_York');

  ApiIsoneFuelMix(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all available fuel types in the database
    router.get('/types', (Request request) async {
      var aux = await coll.distinct('category');
      var types = (aux['values'] as List)..sort();
      return Response.ok(json.encode(types), headers: headers);
    });

    /// Get the hourly generation mw by type.  If type == 'all' return the sum
    /// over all types.
    router.get('/hourly/mw/type/<type>/start/<startDate>/end/<endDate>',
        (Request request, String type, String startDate, String endDate) async {
      late List<Map<String, dynamic>> aux;
      if (type.toLowerCase() == 'all') {
        aux = await getAllMw(startDate, endDate);
      } else {
        aux = await getMw(Uri.decodeComponent(type), startDate, endDate);
      }
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/hourly/marginal_fuel/start/<startDate>/end/<endDate>',
        (Request request, String startDate, String endDate) async {
      var aux = await getMarginalFuel(startDate, endDate);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> getMw(
      String category, String startDate, String endDate) async {
    var query = where;
    query = query.eq('category', category);
    query = query.gte('date', Date.parse(startDate).toString());
    query = query.lte('date', Date.parse(endDate).toString());
    query = query.excludeFields(['_id', 'category', 'isMarginal']);
    return coll.find(query).toList();
  }

  /// Need to aggregate (sum) over all the fuel types.
  Future<List<Map<String, dynamic>>> getAllMw(
      String startDate, String endDate) async {
    var pipeline = <Map<String, Object>>[
      {
        '\$match': {
          'date': {
            '\$gte': Date.parse(startDate).toString(),
            '\$lte': Date.parse(endDate).toString(),
          },
        }
      },
      {
        '\$project': {
          '_id': 0,
          'isMarginal': 0,
          'category': 0,
        }
      },
      // expand each mw array with their index
      {
        '\$unwind': {
          'path': '\$mw',
          'includeArrayIndex': 'index',
        }
      },
      // sum the mw over the fuel type
      {
        '\$group': {
          '_id': {
            'date': '\$date',
            'index': '\$index',
          },
          'mw': {
            '\$sum': '\$mw',
          }
        },
      },
      // flatten the documents
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          'index': '\$_id.index',
          'mw': '\$mw',
        },
      },
      // sort the documents by date and hours
      {
        '\$sort': {
          'date': 1,
          'index': 1,
        },
      },
      // reconstruct the mw array
      {
        '\$group': {
          '_id': {
            'date': '\$date',
          },
          'mw': {
            '\$push': '\$mw',
          },
        },
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          'mw': '\$mw',
        },
      },
      {
        '\$sort': {
          'date': 1,
        },
      },
    ];

    var res = await coll.aggregateToStream(pipeline).toList();

    return res;
  }

  Future<List<Map<String, dynamic>>> getMarginalFuel(
      String startDate, String endDate) async {
    var query = where;
    query = query.gte('date', Date.parse(startDate).toString());
    query = query.lte('date', Date.parse(endDate).toString());
    query = query.excludeFields(['_id', 'date', 'mw']);
    var rows = coll.find(query);
    var out = <Map<String, dynamic>>[];
    await for (var row in rows) {
      // loop over the time of the day
      for (var i = 0; i < row['timestamp'].length; i++) {
        out.add({
          'timestamp':
              TZDateTime.from(row['timestamp'][i], location).toString(),
          'marginalFlag': row['marginalFlag'][i],
        });
      }
    }
    return out;
  }
}
