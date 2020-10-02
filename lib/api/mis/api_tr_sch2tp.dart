library api.tr_sch2tp;

import 'dart:async';
import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';

@ApiClass(name: 'tr_sch2tp', version: 'v1')
class TrSch2tp {
  DbCollection coll;
  Location location;
  var collectionName = 'tr_sch2tp';

  TrSch2tp(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  @ApiMethod(path: 'accountId/{accountId}/start/{start}/end/{end}')

  /// [start], [end] are months in yyyy-mm format.  Return all account,
  /// subaccount data for all settlements.
  Future<ApiResponse> reportData(
      String accountId, String start, String end) async {
    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();
    var query = where
      ..eq('account', accountId)
      ..gte('month', startMonth)
      ..lte('month', endMonth)
      ..excludeFields(['_id', 'account']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  /// One entry for the month, aggregate the 3 blocks together
  @ApiMethod(
      path:
          'accountId/{accountId}/start/{start}/end/{end}/settlement/{settlement}/summary')
  Future<ApiResponse> summaryForAccount(
      String accountId, String start, String end, int settlement) async {
    var out = await _getSummary(accountId, null, start, end, settlement);
    return ApiResponse()..result = json.encode(out);
  }

  @ApiMethod(
      path:
          'accountId/{accountId}/subaccountId/{subaccountId}/start/{start}/end/{end}/settlement/{settlement}/summary')
  Future<ApiResponse> summaryForSubaccount(String accountId,
      String subaccountId, String start, String end, int settlement) async {
    var out =
        await _getSummary(accountId, subaccountId, start, end, settlement);
    return ApiResponse()..result = json.encode(out);
  }

  Future<List<Map<String, dynamic>>> _getSummary(String accountId,
      String subaccountId, String start, String end, int settlement) async {
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
