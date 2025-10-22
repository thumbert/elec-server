import 'dart:async';
import 'dart:convert';

import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class TrSch3p2 {
  late DbCollection coll;
  Location? location;
  var collectionName = 'tr_sch3p2';

  TrSch3p2(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/accountId/<accountId>/start/<start>/end/<end>',
        (Request request, String accountId, String start, String end) async {
      var aux = await dataForAccount(accountId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/accountId/<accountId>/subaccountId/<subaccountId>/start/<start>/end/<end>',
        (Request request, String accountId, String subaccountId, String start,
            String end) async {
      var aux = await dataForSubaccount(accountId, subaccountId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// [start], [end] are months in yyyy-mm format.  Return all account,
  /// subaccount data for all settlements.
  Future<List<Map<String, dynamic>>> dataForAccount(
      String accountId, String start, String end) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 0)
      ..gte('month', startMonth)
      ..lte('month', endMonth)
      ..excludeFields(['_id', 'account', 'tab']);
    return coll.find(query).toList();
  }

  /// [start], [end] are months in yyyy-mm format.  Return all
  /// subaccount data for all settlements.
  Future<List<Map<String, dynamic>>> dataForSubaccount(
      String accountId, String subaccountId, String start, String end) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();
    var query = where
      ..eq('account', accountId)
      ..eq('Subaccount ID', subaccountId)
      ..eq('tab', 1)
      ..gte('month', startMonth)
      ..lte('month', endMonth)
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    return coll.find(query).toList();
  }
}
