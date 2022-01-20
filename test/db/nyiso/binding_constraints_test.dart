library test.db.nyiso.binding_constraints_test;

import 'package:elec/elec.dart';
import 'package:elec_server/api/nyiso/api_nyiso_bindingconstraints.dart';
import 'package:elec_server/src/db/nyiso/binding_constraints.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = NyisoDaBindingConstraintsReportArchive();
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
    var api = BindingConstraints(
      archive.db,
    );
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('Get all constraints between two dates', () async {
      var res =
          await api.apiGetDaBindingConstraintsByDay('2019-01-01', '2019-01-02');
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
      var res = await api.apiGetBindingConstraintsForName(
          'DA', 'CENTRAL EAST - VC', '2019-01-01', '2019-01-06');
      expect(res.length, 136);
      expect(res.first.keys.toSet(), {'hourBeginning', 'contingency', 'cost'});
    });
  });
  // group('Binding constraints client tests:', () {
  //   var client = BindingConstraintsApi(http.Client(), rootUrl: rootUrl);
  //   test('get da binding constraints data for 3 days', () async {
  //     var interval = Interval(
  //         TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2017, 1, 3));
  //     var aux = await client.getDaBindingConstraints(interval);
  //     expect(aux.length, 44);
  //     var first = aux.first;
  //     expect(first, {
  //       'Constraint Name': 'SHFHGE',
  //       'Contingency Name': 'Interface',
  //       'Interface Flag': 'Y',
  //       'Marginal Value': -7.31,
  //       'hourBeginning': '2017-01-01 00:00:00.000-0500',
  //     });
  //   });
  //   test('get all occurrences of constraint Paris', () async {
  //     var name = 'PARIS   O154          A LN';
  //     var aux = await client.getDaBindingConstraint(
  //         name, Date.utc(2017, 1, 5), Date.utc(2017, 1, 6));
  //     expect(aux.length, 2);
  //   });
  //   test('get constraint indicator', () {});
  // });
}

void main() async {
  initializeTimeZones();

  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
