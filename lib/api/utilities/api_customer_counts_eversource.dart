import 'dart:async';

import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:elec_server/src/utils/api_response.dart';


@ApiClass(name: 'utility', version: 'v1')
class ApiCustomerCounts {
  DbCollection coll1;

  ApiCustomerCounts(Db db) {
    coll1 = db.collection('eversource_customer_counts');
  }

  /// get available zones
  @ApiMethod(path: 'customercounts/eversource/zones')
  Future<List<String>> eversourceZones() async {
    var rows = await coll1.distinct('zone');
    var out = (rows['values'] as List).cast<String>();
    return out..sort();
  }

  /// return the historical counts and usage by zone
  @ApiMethod(path: 'customercounts/eversource/zone/{zone}')
  Future<ApiResponse> eversourceCustomerCounts(String zone) async {
    SelectorBuilder query = where;
    query.eq('zone', zone);
    query = query.excludeFields(['_id']);
    var res = await coll1.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }
}



