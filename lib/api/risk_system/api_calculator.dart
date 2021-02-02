library api.risk_system.api_calculator;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/risk_system/calculator_archive.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiCalculators {
  DbCollection coll;
  String collectionName = 'calculators';

  ApiCalculators(Db db) {
    coll = db.collection(collectionName);
  }
  Router get router {
    final router = Router();
    router.get('/users', (Request request) async {
      var users = await getUsers();
      return Response.ok(json.encode(users),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/user/<userId>/names', (Request request, String userId) async {
      var calcs = await calculatorsForUserId(userId);
      return Response.ok(json.encode(calcs),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/user/<userId>/calculator-name/<calculatorName>',
        (Request request, String userId, String calculatorName) async {
      calculatorName = Uri.decodeComponent(calculatorName);
      var calc = await getCalculator(userId, calculatorName);
      return Response.ok(json.encode(calc),
          headers: {'Content-Type': 'application/json'});
    });

    /// If the calculator already exists in the collection, it will fail.
    router.post('/save-calculator', (Request request) async {
      final payload = await request.readAsString();
      var data = json.decode(payload);
      // check that is a valid document before attempting to insert
      if (!CalculatorArchive.isValidDocument(data)) {
        return Response.forbidden('Invalid calculator data: $payload');
      }
      var res = await coll.insert(data);
      return Response.ok(json.encode(res),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/calculator-types', (Request request) async {
      var types = await getCalculatorTypes();
      return Response.ok(json.encode(types),
          headers: {'Content-Type': 'application/json'});
    });

    router.delete('/user/<userId>/calculator-name/<calculatorName>',
        (Request request, String userId, String calculatorName) async {
      await removeCalculator(userId, calculatorName);
      return Response.ok(json.encode({'ok': 1.0}),
          headers: {'Content-Type': 'application/json'});
    });

    return router;
  }

  Future<List<String>> getUsers() async {
    var data = await coll.distinct('userId');
    var types = (data['values'] as List).cast<String>();
    types.sort((a, b) => a.compareTo(b));
    return types;
  }

  Future<List<String>> calculatorsForUserId(String userId) async {
    var data =
        await coll.distinct('calculatorName', where.eq('userId', userId));
    var names = (data['values'] as List).cast<String>();
    names.sort((a, b) => a.compareTo(b));
    return names;
  }

  Future<ApiResponse> getCalculator(
      String userId, String calculatorName) async {
    var res = await coll
        .findOne({'userId': userId, 'calculatorName': calculatorName});
    res.remove('_id');
    return ApiResponse()..result = json.encode(res);
  }

  Future<ApiResponse> removeCalculator(
      String userId, String calculatorName) async {
    var res =
        await coll.remove({'userId': userId, 'calculatorName': calculatorName});
    return ApiResponse()..result = json.encode(res);
  }

  Future<List<String>> getCalculatorTypes() async {
    var data = await coll.distinct('calculatorType');
    var types = (data['values'] as List).cast<String>();
    types.sort((a, b) => a.compareTo(b));
    return types;
  }
}
