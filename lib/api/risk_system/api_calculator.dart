library api.risk_system.api_calculator;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'calculators', version: 'v1')
class ApiCalculators {
  DbCollection coll;
  String collectionName = 'calculators';

  ApiCalculators(Db db) {
    coll = db.collection(collectionName);
  }

  @ApiMethod(path: 'userId/{userId}')
  Future<ApiResponse> calculatorsForUserId(String userId) async {
    var query = where
      ..eq('userId', userId)
      ..excludeFields(['_id']);
    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }

  @ApiMethod(path: 'calculatorTypes')
  Future<List<String>> getCalculatorTypes() async {
    var data = await coll.distinct('calculatorType');
    var types = (data['values'] as List).cast<String>();
    types.sort((a, b) => a.compareTo(b));
    return types;
  }
}
