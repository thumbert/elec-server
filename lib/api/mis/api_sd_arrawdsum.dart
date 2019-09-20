library api.sd_arrawdsum;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'sd_arrawdsum', version: 'v1')
class SdArrAwdSum {
  DbCollection coll;
  Location location;
  var collectionName = 'sd_arrawdsum';

  SdArrAwdSum(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
  }

  @ApiMethod(path: 'accountId/{accountId}/start/{start}/end/{end}')
  Future<ApiResponse> reportData(String accountId, String start, String end) async {

    var startMonth = parseMonth(start).toIso8601String();
    var endMonth = parseMonth(end).toIso8601String();

    var query = where;
    query.eq('account', accountId);
    query.gte('month', startMonth);
    query.lte('month', endMonth);
    query.excludeFields(['_id', 'account']);

    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

}
