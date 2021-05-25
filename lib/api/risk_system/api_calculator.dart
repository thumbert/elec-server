library api.risk_system.api_calculator;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/risk_system/calculator_archive.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiCalculators {
  late DbCollection coll;
  String collectionName = 'calculators';

  ApiCalculators(Db db) {
    coll = db.collection(collectionName);
  }
  var headers = {
    'Content-Type': 'application/json',
    // 'Access-Control-Allow-Origin': '*',
    // 'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
    // 'Access-Control-Allow-Headers': 'Origin, Content-Type',
  };

  Router get router {
    final router = Router();
    router.get('/users', (Request request) async {
      var users = await getUsers();
      return Response.ok(json.encode(users), headers: headers);
    });

    router.get('/user/<userId>/names', (Request request, String userId) async {
      var calcs = await calculatorsForUserId(userId);
      return Response.ok(json.encode(calcs), headers: headers);
    });

    router.get('/user/<userId>/calculator-name/<calculatorName>',
        (Request request, String userId, String calculatorName) async {
      calculatorName = Uri.decodeComponent(calculatorName);
      var calc = await getCalculator(userId, calculatorName);
      return Response.ok(json.encode(calc), headers: headers);
    });

    /// If the calculator already exists in the collection, it will fail.
    router.post('/save-calculator', (Request request) async {
      final payload = await request.readAsString();
      var data = json.decode(payload) as Map<String, dynamic>;
      // check that is a valid document before attempting to insert
      if (!CalculatorArchive.isValidDocument(data)) {
        return Response.forbidden('Invalid calculator data: $payload');
      }
      var res = await coll.insert(data);
      var out = <String, dynamic>{'err': res['err'], 'ok': res['ok']};
      return Response.ok(json.encode(out), headers: headers);
    });

    router.get('/calculator-types', (Request request) async {
      var types = await getCalculatorTypes();
      return Response.ok(json.encode(types), headers: headers);
    });

    router.delete('/user/<userId>/calculator-name/<calculatorName>',
        (Request request, String userId, String calculatorName) async {
      await removeCalculator(userId, calculatorName);
      return Response.ok(json.encode({'ok': 1.0}), headers: headers);
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

  Future<Map<String,dynamic>> getCalculator(
      String userId, String calculatorName) async {
    var res = await (coll
        .findOne({'userId': userId, 'calculatorName': calculatorName}));
    if (res == null) {
      return <String,dynamic>{};
    } else {
      res.remove('_id');
      return res;
    }
  }

  Future<Map<String,dynamic>> removeCalculator(
      String userId, String calculatorName) async {
    var res =
        await coll.remove({'userId': userId, 'calculatorName': calculatorName});
    var out = <String, dynamic>{'err': res['err'], 'ok': res['ok']};
    return out;
  }

  Future<List<String>> getCalculatorTypes() async {
    var data = await coll.distinct('calculatorType');
    var types = (data['values'] as List).cast<String>();
    types.sort((a, b) => a.compareTo(b));
    return types;
  }
}
