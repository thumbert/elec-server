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

  @ApiMethod(path: 'users')
  Future<List<String>> getUsers() async {
    var data = await coll.distinct('userId');
    var types = (data['values'] as List).cast<String>();
    types.sort((a, b) => a.compareTo(b));
    return types;
  }

  @ApiMethod(path: 'userId/{userId}/names')
  Future<List<String>> calculatorsForUserId(String userId) async {
    var data =
        await coll.distinct('calculatorName', where.eq('userId', userId));
    var names = (data['values'] as List).cast<String>();
    names.sort((a, b) => a.compareTo(b));
    return names;
  }

  @ApiMethod(path: 'userId/{userId}/calculatorName/{calculatorName}/remove')
  Future<ApiResponse> calculatorRemove(
      String userId, String calculatorName) async {
    var res =
        await coll.remove({'userId': userId, 'calculatorName': calculatorName});
    return ApiResponse()..result = json.encode(res);
  }

  @ApiMethod(path: 'calculatorTypes')
  Future<List<String>> getCalculatorTypes() async {
    var data = await coll.distinct('calculatorType');
    var types = (data['values'] as List).cast<String>();
    types.sort((a, b) => a.compareTo(b));
    return types;
  }
}
