library api.isone_dacongestion_compact;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:table/table.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class DaCongestionCompact {
  late mongo.DbCollection coll;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'da_congestion_compact';

  DaCongestionCompact(mongo.Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get hourly prices between a start/end date in rle form.
    /// Return a list of Map.  Each element of the list is for one day for all
    /// the nodes in the pool.  One day looks like this:
    /// ```
    /// {
    ///   'date': '2019-01-01',
    ///   'ptids': [321, 322, 323, ...],
    ///   'congestion': [
    ///      [0.02, 1, 0.01, 3, 0.0, 1, 0.01, 1, 0.02, 2, ...],  // for 321
    ///      [...], // for 322
    ///      ...
    ///   ],
    /// }
    /// ```
    router.get('/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await getPrices(Date.parse(start), Date.parse(end));
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> getPrices(Date start, Date end) async {
    var query = mongo.where
      ..gte('date', start.toString())
      ..lte('date', end.toString())
      ..excludeFields(['_id'])
      ..sortBy('date');
    var data = coll.find(query).toList();
    return data;
  }
}
