library api.utilities.api_load_eversource;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:elec_server/src/utils/api_response.dart';


@ApiClass(name: 'eversource_load', version: 'v1')
class ApiLoadEversource {
  DbCollection coll1;

  ApiLoadEversouce(Db db) {
    coll1 = db.collection('load_ct');
  }


//  /// return the historical counts and usage by zone
//  @ApiMethod(path: 'zone/ct/start/{start}/end/{end}')
//  Future<ApiResponse> eversourceCustomerCounts(String start, String end) async {
//
//
//    SelectorBuilder query = where;
//    query.eq('zone', zone);
//    query = query.excludeFields(['_id']);
//    var res = await coll1.find(query).toList();
//    return ApiResponse()..result = json.encode(res);
//  }
//
//  /// get unique utilities/zones/service/rateclass combos
//  @ApiMethod(path: 'customercounts/unique/utility/zone/service/rateclass')
//  Future<ApiResponse> uniqueUtilityZoneServiceRateClass() async {
//    var pipeline = [];
//    pipeline.add({
//      '\$group': {
//        '_id': {'zone': '\$zone', 'service': '\$service',
//          'rateClass': '\$rateClass'},
//      }
//    });
//    var res = await coll1.aggregateToStream(pipeline);
//    var out = <Map<String, dynamic>>[];
//    await for (var e in res) {
//      out.add({'utility': 'eversource'}..addAll(e['_id']));
//    }
//    return ApiResponse()..result = json.encode(out);
//  }

}



