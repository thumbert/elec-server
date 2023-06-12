library api.pjm.api_pjm_ptids;

import 'dart:async';

import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiPtids {
  late DbCollection coll;
  String collectionName = 'pnode_table';

  ApiPtids(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get the current table
    router.get('/current', (Request request) async {
      var aux = await ptidTableCurrent();
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get the table from asOfDate
    router.get('/asofdate/<asOfDate>',
        (Request request, String asOfDate) async {
      var aux = await ptidTableAsOfDate(asOfDate);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get the asOfDays this ptid is in the collection
    router.get('/ptid/<ptid>', (Request request, String ptid) async {
      var aux = await apiPtid(int.parse(ptid));
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get the available asOfDates
    router.get('/dates', (Request request) async {
      var aux = await getAvailableAsOfDates();
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Get the latest ptid table in the database.
  Future<List<Map<String, dynamic>>> ptidTableCurrent() async {
    // Should find a way to do this in one query
    var last =
        await getAvailableAsOfDates().then((List days) => days.last as String);
    var query = where
      ..eq('asOfDate', last)
      ..sortBy('ptid')
      ..excludeFields(['_id', 'asOfDate']);

    /// After a given driver version, the 'ptid' field ended up being a mixture
    /// of int and Int64.  For example this value 2155501806 is returned as
    /// an Int64.  No idea why.  Correcting for it below otherwise the
    /// json.encoding fails!
    var xs = coll.find(query).map((e) {
      e['ptid'] = e['ptid'].toInt();
      return e;
    });
    return xs.toList();
  }

  Future<List<Map<String, dynamic>>> ptidTableAsOfDate(String asOfDate) async {
    var asOf = Date.parse(asOfDate);
    var days = await getAvailableAsOfDates()
        .then((days) => days.map((e) => Date.parse(e)));
    var last =
        days.firstWhere((e) => !e.isBefore(asOf), orElse: () => days.last);
    var query = where
      ..eq('asOfDate', last.toString())
      ..excludeFields(['_id', 'asOfDate']);
    return coll.find(query).toList();
  }

  /// Show the days when this ptid is in the database.  Nodes are
  /// retired from time to time.
  /// Each element is in this form: {'asOfDate': '2019-01-10'}
  Future<List<Map<String, dynamic>>> apiPtid(int ptid) async {
    var query = where
      ..eq('ptid', ptid)
      ..fields(['asOfDate'])
      ..excludeFields(['_id']);
    return coll.find(query).toList();
  }

  Future<List<String>> getAvailableAsOfDates() async {
    Map data = await coll.distinct('asOfDate');
    var days = (data['values'] as List).cast<String>();
    days.sort((a, b) => a.compareTo(b));
    return days;
  }
}
