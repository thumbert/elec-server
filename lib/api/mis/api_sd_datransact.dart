import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SdDaTransact {
  late DbCollection coll;
  Location? location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'sd_datransact';

  SdDaTransact(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/accountId/<accountId>/tab/<tab>/start/<start>/end/<end>',
        (Request request, String accountId, String tab, String start,
            String end) async {
      var aux =
          await getTransactionsForTab(accountId, int.parse(tab), start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/accountId/<accountId>/tab/1/otherParty/<otherParty>/start/<start>/end/<end>',
        (Request request, String accountId, String otherParty, String start,
            String end) async {
      var aux = await getIbmTransactionsForParty(
          accountId, int.parse(otherParty), start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  //http://localhost:8080/sd_datransact/v1/accountId/000050428/tab/0/start/20190101/end/20190101
  Future<List<Map<String, dynamic>>> getTransactionsForTab(
      String accountId, int tab, String start, String end) async {
    var query = where;
    query.eq('account', accountId);
    query.eq('tab', tab);
    query.gte('date', Date.parse(start).toString());
    query.lte('date', Date.parse(end).toString());
    query.excludeFields(['_id', 'account', 'tab']);

    return coll.find(query).toList();
  }

  //http://localhost:8080/sd_datransact/v1/accountId/000050428/tab/1/otherParty/153/start/20190701/end/20190701
  // @ApiMethod(
  //     path:
  //         'accountId/{accountId}/tab/1/otherParty/{otherParty}/start/{start}/end/{end}')
  Future<List<Map<String, dynamic>>> getIbmTransactionsForParty(
      String accountId, int otherParty, String start, String end) async {
    var query = where;
    query.eq('account', accountId);
    query.eq('tab', 1);
    query.eq('Other Party', otherParty);
    query.gte('date', Date.parse(start).toString());
    query.lte('date', Date.parse(end).toString());
    query.excludeFields(['_id', 'account', 'tab']);

    return coll.find(query).toList();
  }
}
