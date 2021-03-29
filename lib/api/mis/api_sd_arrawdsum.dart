library api.sd_arrawdsum;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/lib_mis_reports.dart';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:table/table.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SdArrAwdSum {
  DbCollection coll;
  Location location;
  var collectionName = 'sd_arrawdsum';

  SdArrAwdSum(Db db) {
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
      var aux = await reportData(accountId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/dollars/accountId/<accountId>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String accountId, String start, String end,
            String settlement) async {
      var aux = await arrDollars(accountId, start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/dollars/accountId/<accountId>/subaccountId/<subaccountId>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String accountId, String subaccountId, String start,
            String end, String settlement) async {
      var aux = await arrDollarsForSubaccount(
          accountId, subaccountId, start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> reportData(
      String accountId, String start, String end) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();

    var query = where
      ..eq('account', accountId)
      ..gte('month', startMonth)
      ..lte('month', endMonth)
      ..excludeFields(['_id', 'account']);

    return coll.find(query).toList();
  }

  Future<List<Map<String, dynamic>>> arrDollars(
      String accountId, String start, String end, int settlement) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 0)
      ..gte('month', startMonth)
      ..lte('month', endMonth)
      ..excludeFields(['_id'])
      ..fields([
        'version',
        'account',
        'month',
        'Market Name',
        'Location ID',
        'Peak Hour Load',
        'Load Share Dollars'
      ]);
    var res = await coll.find(query).toList();
    return _aggregate(res, settlement);
  }

  Future<List<Map<String, dynamic>>> arrDollarsForSubaccount(String accountId,
      String subaccountId, String start, String end, int settlement) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 1)
      ..eq('Subaccount ID', subaccountId)
      ..gte('month', startMonth)
      ..lte('month', endMonth)
      ..excludeFields(['_id'])
      ..fields([
        'version',
        'account',
        'month',
        'Market Name',
        'Location ID',
        'Peak Hour Load',
        'Load Share Dollars'
      ]);
    var res = await coll.find(query).toList();
    return _aggregate(res, settlement);
  }

  List<Map<String, dynamic>> _aggregate(
      List<Map<String, dynamic>> ys, int settlement) {
    var data = getNthSettlement(ys, (e) => e['month'], n: settlement);
    var xs = expandDocument(data, {'month'},
        {'Market Name', 'Location ID', 'Peak Hour Load', 'Load Share Dollars'});

    /// aggregate over Market Name
    var nest = Nest()
      ..key((e) => e['month'])
      ..key((e) => e['Location ID'])
      ..key((e) => e['Peak Hour Load'])
      ..rollup((List x) => sum(x.map((e) => e['Load Share Dollars'])));
    var aux = nest.map(xs);
    var out = flattenMap(
        aux, ['month', 'Location ID', 'Peak Hour Load', 'Load Share Dollars']);
    return out;
  }
}
