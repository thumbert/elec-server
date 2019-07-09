library api.mis.sd_datransact;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'sd_datransact', version: 'v1')
class SdDaTransact {
  DbCollection coll;
  Location location;
  final DateFormat fmt = DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'sd_datransact';

  SdDaTransact(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
  }

  //http://localhost:8080/sd_datransact/v1/accountId/000050428/tab/0/start/20190101/end/20190101
  @ApiMethod(path: 'accountId/{accountId}/tab/{tab}/start/{start}/end/{end}')
  Future<ApiResponse> getTransactionsForTab(
      String accountId, int tab, String start, String end) async {

    var query = where;
    query.eq('account', accountId);
    query.eq('tab', tab);
    query.gte('date', Date.parse(start).toString());
    query.lte('date', Date.parse(end).toString());
    query.excludeFields(['_id', 'account', 'tab']);

    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  //http://localhost:8080/sd_datransact/v1/accountId/000050428/tab/1/other party/153/start/20190701/end/20190701
  @ApiMethod(path: 'accountId/{accountId}/tab/1/otherParty/{otherParty}/start/{start}/end/{end}')
  Future<ApiResponse> getIbmTransactionsForParty(
      String accountId, int otherParty, String start, String end) async {

    var query = where;
    query.eq('account', accountId);
    query.eq('tab', 1);
    query.eq('Other Party', otherParty);
    query.gte('date', Date.parse(start).toString());
    query.lte('date', Date.parse(end).toString());
    query.excludeFields(['_id', 'account', 'tab']);

    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }
}
