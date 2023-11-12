library test.db.nyiso.binding_constraints_test;

import 'package:elec_server/src/db/nyiso/btm_solar_actual_mw.dart';
import 'package:elec_server/src/db/nyiso/btm_solar_forecast_mw.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';

/// Tests both for actuals and for forecast!

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = NyisoBtmSolarActualArchive();
  var archiveF = NyisoBtmSolarForecastArchive();
  group('NYISO btm solar actuals db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read file for 2020-11-17', () async {
      var date = Date.utc(2020, 11, 17);
      var file = archive.getCsvFile(date);
      var data = archive.processFile(file);
      expect(data.length, 12);  // 11 zones + total system
      expect(data.first.keys.toSet(), {'type', 'date', 'ptid', 'mw'});
      expect((data.first['mw'] as List).length, 24);
      expect(data.first['type'], 'estimatedActual');
      expect(data.map((e) => e['ptid']).contains(-1), true);  // System
    });
  });
  group('NYISO btm solar forecast db tests:', () {
    setUp(() async => await archiveF.db.open());
    tearDown(() async => await archiveF.dbConfig.db.close());
    test('read file for 2020-11-17', () async {
      var date = Date.utc(2020, 11, 17);
      var file = archiveF.getCsvFile(date);
      var data = archiveF.processFile(file);
      expect(data.length, 12);  // 11 zones + total system
      expect(data.first.keys.toSet(), {'type', 'date', 'ptid', 'mw'});
      expect((data.first['mw'] as List).length, 24);
      expect(data.first['type'], 'forecast');
      expect(data.map((e) => e['ptid']).contains(-1), true);  // System
    });
  });


  // group('NYISO btm solar API tests:', () {
  //   var bc = api.BindingConstraints(
  //     archive.db,
  //   );
  //   setUp(() async => await archive.db.open());
  //   tearDown(() async => await archive.db.close());
  //   test('Get total hourly cost by binding constraint', () async {
  //     var res = await bc.apiGetDaBindingConstraintsHourlyCost(
  //         '2019-12-15', '2019-12-19');
  //     expect(res.length, 26);
  //     // print(res.map((e) => e['constraintName']).join('\n'));
  //     expect(
  //         res.first.keys.toSet(), {'constraintName', 'hourBeginning', 'cost'});
  //     var x = res.firstWhere(
  //             (e) => e['constraintName'] == 'E13THSTA 345 FARRAGUT 345 1');
  //     expect(x['hourBeginning'].last, 1576814400000);
  //     expect(x['cost'].last, 16.84);
  //   });
  //   test('Get all constraints between two dates', () async {
  //     var res =
  //     await bc.apiGetDaBindingConstraintsByDay('2019-01-01', '2019-01-02');
  //     // print(res.map((e) => e['limitingFacility']).join('\n'));
  //     expect(res.length, 14);
  //     var x0 =
  //     res.firstWhere((e) => e['limitingFacility'] == 'CENTRAL EAST - VC');
  //     expect(x0.keys.toSet(), {'limitingFacility', 'hours'});
  //     expect(x0['hours'].first, {
  //       'hourBeginning': '2019-01-01T00:00:00.000-0500',
  //       'contingency': 'BASE CASE',
  //       'cost': 21.24,
  //     });
  //   });
  //   test('Get one constraint between two dates', () async {
  //     var res = await bc.apiGetBindingConstraintsForName(
  //         'DA', 'CENTRAL EAST - VC', '2019-01-01', '2019-01-06');
  //     expect(res.length, 136);
  //     expect(res.first.keys.toSet(), {'hourBeginning', 'contingency', 'cost'});
  //     var url = '$rootUrl/nyiso/bc/v1/market/da/'
  //         'constraintname/CENTRAL EAST - VC/start/2019-01-01/end/2019-01-06';
  //     var aux = await http
  //         .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
  //     var data = json.decode(aux.body) as List;
  //     expect(data.length, 136);
  //   });
  //   test('Get daily cost for all constraints between start/end date', () async {
  //     var url = '$rootUrl/nyiso/bc/v1/market/da/'
  //         'start/2019-01-01/end/2019-01-03/dailycost';
  //     var aux = await http
  //         .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
  //     var data = json.decode(aux.body) as List;
  //     expect(data.length, 22);
  //     var x = data.firstWhere((e) =>
  //     e['date'] == '2019-01-01' &&
  //         e['constraintName'] == 'CENTRAL EAST - VC');
  //     expect(x, {
  //       'date': '2019-01-01',
  //       'constraintName': 'CENTRAL EAST - VC',
  //       'cost': 280.14,
  //     });
  //   });
  // });
  // group('Binding constraints client tests:', () {
  //   var client =
  //   BindingConstraints(http.Client(), iso: Iso.newYork, rootUrl: rootUrl);
  //   test('get hourly da binding constraints data for 2 days', () async {
  //     var interval = Interval(
  //         TZDateTime(location, 2019, 1, 1), TZDateTime(location, 2019, 1, 3));
  //     var aux = await client.getDaBindingConstraints(interval);
  //     expect(aux.length, 11);
  //     var ce = aux['CENTRAL EAST - VC']!;
  //     expect(
  //         ce.first,
  //         IntervalTuple<num>(
  //             Hour.beginning(TZDateTime(location, 2019)), 21.24));
  //   });
  //
  //   test('get hourly da binding constraints data for 2 years, speed test',
  //           () async {
  //         var interval = Interval(
  //             TZDateTime(location, 2019, 1, 1), TZDateTime(location, 2020, 12, 31));
  //         var sw = Stopwatch()..start();
  //         var aux = await client.getDaBindingConstraints(interval);
  //         sw.stop();
  //         var elapsed = sw.elapsedMilliseconds;
  //
  //         /// on laptop 761 ms, 2/13/2022
  //         expect(elapsed < 1000, true); // 761 ms
  //         expect(aux.isNotEmpty, true);
  //       });
  //   test('get daily cost by constraint', () async {
  //     var start = Date.utc(2019, 1, 1);
  //     var end = Date.utc(2019, 1, 3);
  //     var xs = await client.dailyConstraintCost(start, end);
  //     expect(xs.length, 22);
  //     var x = xs.firstWhere((e) =>
  //     e['date'] == '2019-01-01' &&
  //         e['constraintName'] == 'CENTRAL EAST - VC');
  //     expect(x, {
  //       'date': '2019-01-01',
  //       'constraintName': 'CENTRAL EAST - VC',
  //       'cost': 280.14,
  //     });
  //   });
  //   test('get all occurrences of constraint CENTRAL EAST - VC', () async {
  //     var name = 'CENTRAL EAST - VC';
  //     var aux = await client.getDaBindingConstraint(
  //         name, Date.utc(2019, 1, 1), Date.utc(2019, 1, 3));
  //     expect(aux.length, 64);
  //   });
  // });
}

Future<void> main() async {
  initializeTimeZones();
  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
