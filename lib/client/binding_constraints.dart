library elec_server.client.binding_constraints.v1;

import 'dart:async';
import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

/// A multi region client for getting binding constraints data
class BindingConstraints {
  String rootUrl;
  String servicePath;
  final Iso iso;
  final location = getLocation('America/New_York');

  BindingConstraints(http.Client client,
      {required this.iso,
      this.rootUrl = 'http://localhost:8080',
      this.servicePath = '/bc/v1/'});

  final _isoMap = <Iso, String>{
    Iso.newEngland: '',
    Iso.newYork: '/nyiso',
  };

  /// Get all the constraints in a given interval.
  /// For NYISO each element of the list is a map with form
  /// ```
  /// {
  ///   'limitingFacility': 'CENTRAL EAST - VC',
  ///   'hours': [
  ///      {
  ///        'hourBeginning': '2019-01-01T00:00:00.000-0500',
  ///        'contingency': 'BASE CASE',
  ///        'cost': 21.24,
  ///      }, ...
  ///   ],
  /// }
  /// ```
  /// Note that each element is for one day.
  Future<List<Map<String, dynamic>>> getDaBindingConstraints(
      Interval interval) async {
    var start = Date.fromTZDateTime(interval.start);
    Date end;
    if (isBeginningOfDay(interval.end)) {
      end = Date.fromTZDateTime(interval.end.subtract(Duration(seconds: 1)));
    } else {
      end = Date.fromTZDateTime(interval.end);
    }
    var _url = rootUrl +
        _isoMap[iso]! +
        servicePath +
        'market/da' +
        '/start/${start.toString()}' +
        '/end/${end.toString()}';
    var _response = await http.get(Uri.parse(_url));
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }

  /// Calculate the total cost of this constraint for the day.
  /// Input [xs] is the data returned by [getDaBindingConstraints].
  /// Return a list with elements in this form
  /// ```
  /// {
  ///   'date': '2019-01-01',
  ///   'constraintName': 'CENTRAL EAST - VC',
  ///   'cost': 187.23,
  /// }
  /// ```
  /// This is a format convenient to summarize in a table.
  Future<List<Map<String, dynamic>>> dailyConstraintCost(
      Date start, Date end) async {
    var _url = rootUrl +
        _isoMap[iso]! +
        servicePath +
        'market/da' +
        '/start/${start.toString()}' +
        '/end/${end.toString()}/dailycost';
    var _response = await http.get(Uri.parse(_url));
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }

  /// Get all the occurrences of this constraint in the history.
  Future<List<Map<String, dynamic>>> getDaBindingConstraint(
      String name, Date start, Date end) async {
    var _url = rootUrl +
        _isoMap[iso]! +
        servicePath +
        'market/da' +
        '/constraintname/' +
        Uri.encodeComponent(name) +
        '/start/${start.toString()}' +
        '/end/${end.toString()}';

    var _response = await http.get(Uri.parse(_url));
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }
}
