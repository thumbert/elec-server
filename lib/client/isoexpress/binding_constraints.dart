library elec_server.client.binding_constraints.v1;

import 'dart:async';
import 'dart:convert';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';


const String USER_AGENT = 'dart-api-client binding_constraints/v1';

class BindingConstraintsApi {
  String rootUrl;
  String servicePath;
  final location = getLocation('America/New_York');

  BindingConstraintsApi(http.Client client,
      {this.rootUrl: "http://localhost:8080/", this.servicePath: "bc/v1/"});

  /// Get all the constraints in a given interval.
  Future<List<Map<String,dynamic>>> getDaBindingConstraints(Interval interval) async {
    var start = Date.fromTZDateTime(interval.start);
    Date end;
    if (isBeginningOfDay(interval.end)) {
      end =
          Date.fromTZDateTime(interval.end.subtract(new Duration(seconds: 1)));
    } else {
      end = Date.fromTZDateTime(interval.end);
    }

    var _url = rootUrl + servicePath + 'market/da' +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
  }


  /// Get all the occurrences of this constraint in the history.
  Future<List<Map<String,dynamic>>> getDaBindingConstraint(String name,
      Date start, Date end) async {
    var _url = rootUrl + servicePath + 'market/da' +
        '/constraintname/' +
        commons.Escaper.ecapeVariable('${name.toString()}') +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
  }


}
