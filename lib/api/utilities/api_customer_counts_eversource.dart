import 'dart:async';

import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import '../../src/utils/api_response.dart';


@ApiClass(name: 'eversource', version: 'v1')
class ApiCustomerCounts {
  DbCollection coll;
  String collectionName = 'customer_counts_ct';

  ApiCustomerCounts(Db db) {
    coll = db.collection(collectionName);
  }

  /// return the historical counts and usage by rate class
  @ApiMethod(path: 'customercounts/ct')
  Future<ApiResponse> customerCountsCt() async {
    SelectorBuilder query = where;
//    query = query.eq('town', town);
//    query = query.eq('variable', 'kWh');
    query = query.excludeFields(['_id']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

}


