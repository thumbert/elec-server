library api.ieso.api_ieso_rtzonaldemand;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';

class ApiIesoRtZonalDemand {
  ApiIesoRtZonalDemand(Db db) {
    coll = db.collection(collectionName);
  }

  late DbCollection coll;
  final String collectionName = 'rt_zonal_demand';

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all zone names
    router.get('/zones', (Request request) async {
      var aux = await coll.distinct('zone');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    /// Get one zone between a start/end date
    router.get('/zone/<zone>/start/<start>/end/<end>',
        (Request request, String zone, String start, String end) async {
      var aux = await getZone(
          zone, Date.parse(start).toString(), Date.parse(end).toString());
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Return the tMin and tMax for a given stationId.  Temperatures are in
  /// Celsius.
  Future<List<Map<String, dynamic>>> getZone(
      String zone, String startDate, String endDate) async {
    var query = where
      ..eq('zone', zone)
      ..gte('date', startDate)
      ..lte('date', endDate)
      ..excludeFields(['_id', 'zone']);
    return coll.find(query).toList();
  }
}
