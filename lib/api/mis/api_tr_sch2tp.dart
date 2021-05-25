library api.tr_sch2tp;

import 'dart:async';
import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class TrSch2tp {
  late DbCollection coll;
  Location? location;
  var collectionName = 'tr_sch2tp';

  TrSch2tp(Db db) {
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
        '/accountId/<accountId>/start/<start>/end/<end>/settlement/<settlement>/summary',
        (Request request, String accountId, String start, String end,
            String settlement) async {
      var aux =
          await summaryForAccount(accountId, start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/accountId/<accountId>/subaccountId/<subaccountId>/start/<start>/end/<end>/settlement/<settlement>/summary',
        (Request request, String accountId, String subaccountId, String start,
            String end, String settlement) async {
      var aux = await summaryForSubaccount(
          accountId, subaccountId, start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// [start], [end] are months in yyyy-mm format.  Return all account,
  /// subaccount data for all settlements.
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

  /// One entry for the month, aggregate the 3 blocks together
  Future<List<Map<String, dynamic>>> summaryForAccount(
      String accountId, String start, String end, int settlement) async {
    return _getSummary(accountId, null, start, end, settlement);
  }

  Future<List<Map<String, dynamic>>> summaryForSubaccount(String accountId,
      String subaccountId, String start, String end, int settlement) async {
    return _getSummary(accountId, subaccountId, start, end, settlement);
  }

  Future<List<Map<String, dynamic>>> _getSummary(String accountId,
      String? subaccountId, String start, String end, int settlement) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();
    var pipeline = [
      {
        '\$match': {
          'account': {'\$eq': accountId},
          'tab': {'\$eq': subaccountId == null ? 0 : 1},
          if (subaccountId != null) 'Subaccount ID': {'\$eq': subaccountId},
          'month': {
            '\$gte': startMonth,
            '\$lte': endMonth,
          },
        },
      },
      {
        '\$project': {
          '_id': 0,
          // 'account': '\$account',
          // if (subaccountId != null) 'Subaccount ID': '\$Subaccount ID',
          'month': '\$month',
          'version': '\$version',
          'Energy Transaction Units': {'\$sum': '\$Energy Transaction Units'},
          'Energy Transaction Units Dollars': {
            '\$sum': '\$Energy Transaction Units Dollars'
          },
          'Volumetric Measures': {'\$sum': '\$Volumetric Measures'},
          'Volumetric Measures Dollars': {
            '\$sum': '\$Volumetric Measures Dollars'
          },
          'Total ISO Schedule 2 Charges': {
            '\$sum': '\$Total ISO Schedule 2 Charges'
          },
        }
      },
    ];

    var res = await coll.aggregateToStream(pipeline).toList();
    var xs = getNthSettlement(res, (e) => e['month'], n: settlement);

    return xs;
  }
}
