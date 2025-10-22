import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/timezone.dart';

class ApiCmeMarks {
  ApiCmeMarks(Db db) {
    coll = db.collection(collectionName);
  }

  late DbCollection coll;
  final String collectionName = 'settlements';

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/price/curvenames/asofdate/<asofdate>',
        (Request request, String asofdate) async {
      var res = await allCurveIds(asofdate);
      return Response.ok(json.encode(res), headers: headers);
    });

    /// Returns a Map with two keys: ['terms', 'values']
    ///
    router.get('/price/curvename/<curvename>/asofdate/<asofdate>',
        (Request request, String curvename, String asofdate) async {
      var res = await getPrice(curvename, asofdate);
      return Response.ok(json.encode(res), headers: headers);
    });

    /// Get all the data needed to calculate the historical price of a
    /// forward strip.
    /// [contractStart] and [contractEnd] are future months.
    /// [start] and [end] define the historical date range.
    ///
    /// Returns a double list.  Each element of the outer list is a list
    ///
    /// ```
    /// [
    ///   ["2023-04-28","2024-01",73.65],
    ///   ["2023-04-28","2024-02",73.23]
    ///   ...
    /// ]
    /// ```
    router.get(
        '/price/curvename/<curveName>/contract_start/<contractStart>/contract_end/<contractEnd>/start/<start>/end/<end>',
        (Request request, String curveName, String contractStart,
            String contractEnd, String start, String end) async {
      late Month monthStart, monthEnd;
      try {
        monthStart = Month.parse(contractStart);
      } catch (e) {
        return Response.badRequest(
            body: 'Failed parsing contract_start value', headers: headers);
      }
      try {
        monthEnd = Month.parse(contractEnd);
      } catch (e) {
        return Response.badRequest(
            body: 'Failed parsing contract_end value', headers: headers);
      }
      var startDate = Date.parse(start, location: UTC);
      var endDate = Date.parse(end, location: UTC);
      var res = await getStripData(
          curveName: curveName,
          contractStart: monthStart,
          contractEnd: monthEnd,
          start: startDate,
          end: endDate);
      return Response.ok(json.encode(res), headers: headers);
    });

    return router;
  }

  /// Return the list of curveIds sorted.
  Future<List<String>> allCurveIds(String asOfDate) async {
    var query = where
      ..eq('fromDate', Date.parse(asOfDate).toString())
      ..fields(['curveId'])
      ..excludeFields(['_id']);
    var aux =
        await coll.find(query).map((e) => e['curveId'] as String).toList();
    return aux..sort();
  }

  Future<Map<String, dynamic>> getPrice(String curveId, String asOfDate) async {
    var query = where
      ..eq('curveId', curveId.toUpperCase())
      ..eq('fromDate', Date.parse(asOfDate).toString())
      ..fields(['terms', 'values'])
      ..excludeFields(['_id']);
    return await coll.findOne(query) ?? <String, dynamic>{};
  }

  /// Each element of the List returned is a List with elements of form
  /// `[asOfDate, contractMonth, value]`
  /// corresponding to one `fromDate`.
  ///
  Future<List<dynamic>> getStripData(
      {required String curveName,
      required Month contractStart,
      required Month contractEnd,
      required Date start,
      required Date end}) async {
    var query = where
      ..eq('curveId', curveName.toUpperCase())
      ..gte('fromDate', start.toString())
      ..lte('fromDate', end.toString())
      ..fields(['fromDate', 'terms', 'values'])
      ..excludeFields(['_id']);
    var aux = await coll.find(query).expand((e) {
      var out = [];
      List terms = e['terms'];
      var iStart = binarySearch(terms, contractStart.toIso8601String());
      var iEnd = binarySearch(terms, contractEnd.toIso8601String());
      if (iStart > 0 && iEnd >= iStart) {
        for (var i = iStart; i <= iEnd; i++) {
          out.add([e['fromDate'], terms[i], e['values']![i]]);
        }
      }
      return out;
    }).toList();
    return aux;
  }
}
