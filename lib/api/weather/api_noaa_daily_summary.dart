library api.weather.api_noaa_daily_summary;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';

class ApiNoaaDailySummary {
  late DbCollection coll;
  String collectionName = 'noaa_daily_summary';

  ApiNoaaDailySummary(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get one stationId between a start/end date
    router.get('/stationId/<stationId>/start/<start>/end/<end>',
        (Request request, String stationId, String start, String end) async {
      var aux = await apiGetStationId(stationId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Return the tMin and tMax for a given stationId.  Temperatures are in
  /// Celsius.
  Future<List<Map<String, dynamic>>> apiGetStationId(
      String stationId, String startDate, String endDate) async {
    var yearStart = int.parse(startDate.substring(0, 4));
    var yearEnd = int.parse(endDate.substring(0, 4));
    var query = where
      ..eq('stationId', stationId)
      ..gte('year', yearStart)
      ..lte('year', yearEnd)
      ..excludeFields(['_id', 'stationId']);
    var xs = await coll.find(query).toList();
    var aux = {for (var x in xs) x['year'] as int: x}; // for faster access

    var out = <Map<String, dynamic>>[];
    var _startDate = Date.parse(startDate, location: UTC);
    var _endDate = Date.parse(endDate, location: UTC);

    var term = Term(_startDate, _endDate);
    var days = term.days();
    var currentYear = _startDate.year;
    var data = aux[currentYear];
    for (var day in days) {
      if (currentYear != day.year) {
        currentYear++;
        data = aux[currentYear];
      }
      if (data != null) {
        /// the year may not be in the database
        var index = day.dayOfYear() - 1;
        if (index < data['tMin'].length) {
          /// this day of the year may not be in the database yet
          out.add({
            'date': day.toString(),
            'tMin': data['tMin'][index],
            'tMax': data['tMax'][index],
          });
        }
      }
    }
    return out;
  }
}
