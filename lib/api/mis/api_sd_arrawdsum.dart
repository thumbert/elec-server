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

  //http://10.101.10.27:8080/sd_arrawdsum/v1/accountId/000050428/start/201801/end/201802
  @ApiMethod(path: 'accountId/000050428/start/{start}/end/{end}')
  Future<ApiResponse> reportData(String start, String end) async {

    var startMonth = Month.parse(start).toIso8601String();
    var endMonth = Month.parse(end).toIso8601String();

    var query = where;
    query.gte('month', startMonth);
    query.lte('month', endMonth);
    query.excludeFields(['_id']);

    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

}
