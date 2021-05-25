library client.risk_system.calculator;

import 'dart:convert';
// import 'package:elec/calculators.dart';
// import 'package:elec/calculators/elec_swap.dart';
// import 'package:elec/calculators/elec_daily_option.dart';
import 'package:http/http.dart' as http;

class CalculatorClient {
  String rootUrl;
  String servicePath;

  late String _baseUrl;

  CalculatorClient(http.Client client,
      {this.rootUrl = 'http://localhost:9080',
      this.servicePath = '/calculators/v1/'}) {
    _baseUrl = rootUrl + servicePath;
  }

  /// Delete a calculator from the database
  Future<Map<String, dynamic>> deleteCalculator(
      String? userId, String? calculatorName) async {
    var url = _baseUrl + 'user/$userId/calculator-name/$calculatorName';
    var aux = await http.delete(Uri.parse(url));
    return json.decode(aux.body) as Map<String, dynamic>;
  }

  /// Get the list of all users
  Future<List<String>> getUsers() async {
    var url = _baseUrl + 'users';
    var aux = await http.get(Uri.parse(url));
    var res = json.decode(aux.body) as List;
    return res.cast<String>();
  }

  /// Get the list of calculator names for a given user
  Future<List<String>> getCalculatorNames(String userId) async {
    var url = _baseUrl + 'user/$userId/names';
    var aux = await http.get(Uri.parse(url));
    var res = json.decode(aux.body) as List;
    return res.cast<String>();
  }

  /// Get a calculator.
  /// Each new type needs to be manually supported.
  /// Return a calculator or [null] if a server error or calculator doesn't
  /// exist.
  // Future<Object> getCalculator(String userId, String calculatorName) async {
  //   var url = _baseUrl + 'user/$userId/calculator-name/$calculatorName';
  //   var aux = await http.get(Uri.parse(url));
  //   var x = json.decode(aux.body) as Map<String, dynamic>;
  //   if (x.containsKey('result')) {
  //     var data = json.decode(x['result']);
  //     if (data['calculatorType'] == 'elec_swap') {
  //       return ElecSwapCalculator.fromJson(data);
  //     } else if (data['calculatorType'] == 'elec_daily_option') {
  //       return ElecDailyOption.fromJson(data);
  //     } else {
  //       throw StateError(
  //           'Unsupported calculatorType: ${data['calculatorType']}');
  //     }
  //   }
  //   return null;
  // }

  /// Post this calculator and save it to the database.
  /// [data] is the output of the [toJson] method on the calculator.
  /// The result is the MongoDb response.
  Future<Map<String, dynamic>> saveCalculator(Map<String, dynamic> data) async {
    var url = _baseUrl + 'save-calculator';
    var aux = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(aux.body) as Map<String, dynamic>;
  }
}
