library test.db.nyiso.binding_constraints_test;

import 'dart:convert';

import 'package:elec/elec.dart';
import 'package:elec_server/api/nyiso/api_nyiso_bindingconstraints.dart' as api;
import 'package:elec_server/client/binding_constraints.dart';
import 'package:elec_server/src/db/nyiso/binding_constraints.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = NyisoDaBindingConstraintsReportArchive();
  var location = getLocation('America/New_York');
  group('NYISO binding constraints db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read binding constraints file for 2020-01-01', () async {
      var date = Date.utc(2020, 1, 1);
      var file = archive.getFile(date);
      var data = archive.processFile(file);
      expect(data.length, 5);
      expect(data.first.keys.toSet(),
          {'market', 'date', 'limitingFacility', 'hours'});
      var c0 =
          data.firstWhere((e) => e['limitingFacility'] == 'CENTRAL EAST - VC');
      expect(c0['hours'].length, 24);
      expect(c0['hours'].first, {
        'hourBeginning': TZDateTime.utc(2020, 1, 1, 5),
        'contingency': 'BASE CASE',
        'cost': 20.26,
      });
    });
  });
  group('Binding constraints API tests:', () {
    var bc = api.BindingConstraints(
      archive.db,
    );
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('Get all constraints between two dates', () async {
      var res =
          await bc.apiGetDaBindingConstraintsByDay('2019-01-01', '2019-01-02');
      // print(res.map((e) => e['limitingFacility']).join('\n'));
      expect(res.length, 14);
      var x0 =
          res.firstWhere((e) => e['limitingFacility'] == 'CENTRAL EAST - VC');
      expect(x0.keys.toSet(), {'limitingFacility', 'hours'});
      expect(x0['hours'].first, {
        'hourBeginning': '2019-01-01T00:00:00.000-0500',
        'contingency': 'BASE CASE',
        'cost': 21.24,
      });
    });
    test('Get one constraint between two dates', () async {
      var res = await bc.apiGetBindingConstraintsForName(
          'DA', 'CENTRAL EAST - VC', '2019-01-01', '2019-01-06');
      expect(res.length, 136);
      expect(res.first.keys.toSet(), {'hourBeginning', 'contingency', 'cost'});
      var url = '$rootUrl/nyiso/bc/v1/market/da/'
          'constraintname/CENTRAL EAST - VC/start/2019-01-01/end/2019-01-06';
      var aux = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as List;
      expect(data.length, 136);
    });
    test('Get daily cost for all constraints between start/end date', () async {
      var url = '$rootUrl/nyiso/bc/v1/market/da/'
          'start/2019-01-01/end/2019-01-03/dailycost';
      var aux = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as List;
      expect(data.length, 22);
      var x = data.firstWhere((e) =>
          e['date'] == '2019-01-01' &&
          e['constraintName'] == 'CENTRAL EAST - VC');
      expect(x, {
        'date': '2019-01-01',
        'constraintName': 'CENTRAL EAST - VC',
        'cost': 280.14,
      });
    });
  });
  group('Binding constraints client tests:', () {
    var client =
        BindingConstraints(http.Client(), iso: Iso.newYork, rootUrl: rootUrl);
    test('get da binding constraints data for 2 days', () async {
      var interval = Interval(
          TZDateTime(location, 2019, 1, 1), TZDateTime(location, 2019, 1, 3));
      var aux = await client.getDaBindingConstraints(interval);
      // print(aux.map((e) => e['limitingFacility']).join('\n'));
      expect(aux.length, 14);
      var first = aux.first;
      expect(first.keys, {'limitingFacility', 'hours'});
      expect(first['hours'].first, {
        'hourBeginning': '2019-01-01T00:00:00.000-0500',
        'contingency': 'BASE CASE',
        'cost': 21.24,
      });
    });
    test('get daily cost by constraint', () async {
      var start = Date.utc(2019, 1, 1);
      var end = Date.utc(2019, 1, 3);
      var xs = await client.dailyConstraintCost(start, end);
      expect(xs.length, 22);
      var x = xs.firstWhere((e) =>
          e['date'] == '2019-01-01' &&
          e['constraintName'] == 'CENTRAL EAST - VC');
      expect(x, {
        'date': '2019-01-01',
        'constraintName': 'CENTRAL EAST - VC',
        'cost': 280.14,
      });
    });
    test('get all occurrences of constraint CENTRAL EAST - VC', () async {
      var name = 'CENTRAL EAST - VC';
      var aux = await client.getDaBindingConstraint(
          name, Date.utc(2019, 1, 1), Date.utc(2019, 1, 3));
      expect(aux.length, 64);
    });
  });
}

void main() async {
  initializeTimeZones();

  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
