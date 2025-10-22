import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SrRsvCharge {
  late DbCollection coll;
  final collectionName = 'sr_rsvcharge';

  SrRsvCharge(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/charges/accountId/<accountId>/start/<start>/end/<end>',
        (Request request, String accountId, String start, String end) async {
      var aux = await chargesAccount(accountId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/charges/accountId/<accountId>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String accountId, String start, String end,
            String settlement) async {
      var aux = await chargesAccountSettlement(
          accountId, start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/charges/accountId/<accountId>/subaccountId/<subaccountId>/start/<start>/end/<end>',
        (Request request, String accountId, String subaccountId, String start,
            String end) async {
      var aux = await chargesSubaccount(accountId, subaccountId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/charges/accountId/<accountId>/subaccountId/<subaccountId>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String accountId, String subaccountId, String start,
            String end, String settlement) async {
      var aux = await chargesSubaccountSettlement(
          accountId, subaccountId, start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Get all data in tab 4, participant section
  Future<List<Map<String, dynamic>>> chargesAccount(
      String accountId, String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 4)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab']);

    return coll.find(query).toList();
  }

  /// Get all data in tab 4, participant section, one settlement
  Future<List<Map<String, dynamic>>> chargesAccountSettlement(
      String accountId, String start, String end, int settlement) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 4)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab']);

    var data = await coll.find(query).toList();
    return getNthSettlement(data, (e) => Tuple2(e['date'], e['Load Zone ID']),
        n: settlement);
  }

  /// tab 6, subaccount section, all settlements
  Future<List<Map<String, dynamic>>> chargesSubaccount(
      String accountId, String subaccountId, String start, String end) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 6)
      ..eq('Subaccount ID', subaccountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    return coll.find(query).toList();
  }

  /// tab 6, subaccount section
  Future<List<Map<String, dynamic>>> chargesSubaccountSettlement(
      String accountId,
      String subaccountId,
      String start,
      String end,
      int settlement) async {
    var query = where
      ..eq('account', accountId)
      ..eq('tab', 6)
      ..eq('Subaccount ID', subaccountId)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'account', 'tab', 'Subaccount ID']);
    var data = await coll.find(query).toList();

    return getNthSettlement(data, (e) => Tuple2(e['date'], e['Load Zone ID']),
        n: settlement);
  }
}
