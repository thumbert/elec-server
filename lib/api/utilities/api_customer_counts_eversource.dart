import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';

@ApiClass(name: 'eversource', version: 'v1')
class ApiCustomerCounts {
  DbCollection coll;
  String collectionName = 'customer_counts_ct';

  ApiCustomerCounts(Db db) {
    coll = db.collection(collectionName);
  }

  /// return the historical counts and usage by rate class
  @ApiMethod(path: 'customercounts/ct')
  Future<List<Map<String, String>>> customerCountsCt() async {
    SelectorBuilder query = where;
//    query = query.eq('town', town);
//    query = query.eq('variable', 'kWh');
    query = query.excludeFields(['_id']);
    return await coll.find(query).toList();
  }

}


