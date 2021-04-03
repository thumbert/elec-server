library api.utilities.api_competitive_suppliers_eversource;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:date/date.dart';

// @ApiClass(name: 'eversource_competitive_suppliers', version: 'v1')
class ApiCompetitiveCustomerCountsCt {
  DbCollection coll1;

  ApiCompetitiveCustomerCountsCt(Db db) {
    coll1 = db.collection('eversource_competitive_suppliers');
  }

  /// get all suppliers
  // @ApiMethod(path: 'customercounts/ct/start/{start}/end/{end}')
  Future<ApiResponse> getCustomerCounts(String start, String end) async {

    var query = where;
    query.gte('month', Date.parse(start).toString().substring(0,7));
    query.lte('month', Date.parse(end).toString().substring(0,8));
    query.sortBy('month');
    query = query.excludeFields(['_id']);
    var res = await coll1.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  /// get only one supplier
  // @ApiMethod(path: 'customercounts/ct/supplier/{supplier}')
  Future<ApiResponse> getCustomerCountsFor(String supplier) async {
    var query = where;
    query.gte('supplierName', supplier);
    query.sortBy('month');
    query = query.excludeFields(['_id']);
    var res = await coll1.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

}



