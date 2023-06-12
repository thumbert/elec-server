import 'package:elec/elec.dart';
import 'package:elec_server/api/isoexpress/api_isone_bindingconstraints.dart'
    as api;
import 'package:elec_server/client/binding_constraints.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:timezone/timezone.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  var archive = DaBindingConstraintsReportArchive();
  group('Binding constraints db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read binding constraints file for 2017-12-31', () async {
      var file = archive.getFilename(Date.utc(2017, 12, 31));
      var data = archive.processFile(file);
      expect(data.length, 1);
      expect(data.first.keys.toList(), ['market', 'date', 'constraints']);
      var c0 = data.first['constraints'] as List;
      expect(c0.length, 36);
      expect(c0.first, {
        'Constraint Name': 'BNGW',
        'Contingency Name': 'Interface',
        'Interface Flag': 'Y',
        'Marginal Value': -69.34,
        'hourBeginning': TZDateTime(UTC, 2017, 12, 31, 5),
      });
    });
    test('empty file for 2015-02-17', () async {
      var file = archive.getFilename(Date.utc(2015, 2, 17));
      var data = archive.processFile(file);
      expect(data.isEmpty, true);
    });
    test('DA Binding Constraints Report for 2018-07-10 has duplicates',
        () async {
      var file = archive.getFilename(Date.utc(2018, 7, 10));
      var data = archive.processFile(file);
      // 20 entries in the file, only 10 are unique
      var constraints = data.first['constraints'] as List;
      expect(constraints.length, 10);
    });
  });
  //
  //
  group('Binding constraints API tests:', () {
    var bc = api.BindingConstraints(
      archive.db,
    );
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('Get all constraints between two dates', () async {
      var res =
          await bc.apiGetDaBindingConstraintsByDay('2017-01-01', '2017-01-02');
      expect(res.length, 44);
      var x0 = res.firstWhere((e) =>
          e['Constraint Name'] == 'SHFHGE' &&
          e['hourBeginning'] == '2017-01-01 00:00:00.000-0500');
      expect(x0, {
        'Constraint Name': 'SHFHGE',
        'Contingency Name': 'Interface',
        'Interface Flag': 'Y',
        'Marginal Value': -7.31,
        'hourBeginning': '2017-01-01 00:00:00.000-0500'
      });
    });
    test('Get hourly cost by constraint between two dates', () async {
      var res = await bc.apiGetDaBindingConstraintsHourlyCost(
          '2017-01-01', '2017-01-02');
      expect(res.length, 2);
      var x0 = res.firstWhere((e) => e['constraintName'] == 'NYNE');
      expect(x0.keys, {'constraintName', 'hourBeginning', 'cost'});
      expect(x0['hourBeginning'].first, 1483308000000);
      expect(x0['cost'].first, -12.83);
    });
    test('Get one constraint between two dates', () async {
      var res = await bc.apiGetBindingConstraintsByName(
          'DA', 'PARIS   O154          A LN', '2017-01-05', '2017-01-06');
      expect(res.length, 2);
    });
  });
  //
  //
  group('Binding constraints client tests:', () {
    var client = BindingConstraints(http.Client(),
        iso: Iso.newEngland, rootUrl: rootUrl);
    test('get da binding contraints', () async {
      var term = Term.parse('1Jan17-2Jan17', location);
      var res = await client.getDaBindingConstraints(term.interval);
      var nyne = res['NYNE']!;
      expect(nyne.length, 2);
    });
    test('get da binding constraints data for 3 days, details', () async {
      var interval = Interval(
          TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2017, 1, 3));
      var aux = await client.getDaBindingConstraintsDetails(interval);
      expect(aux.length, 44);
      var first = aux.first;
      expect(first, {
        'Constraint Name': 'SHFHGE',
        'Contingency Name': 'Interface',
        'Interface Flag': 'Y',
        'Marginal Value': -7.31,
        'hourBeginning': '2017-01-01 00:00:00.000-0500',
      });
    });
    test('get all occurrences of constraint Paris', () async {
      var name = 'PARIS   O154          A LN';
      var aux = await client.getDaBindingConstraint(
          name, Date.utc(2017, 1, 5), Date.utc(2017, 1, 6));
      expect(aux.length, 2);
    });
    test('get constraint indicator', () {});
  });
}

Future<void> main() async {
  initializeTimeZones();
  // await DaBindingConstraintsReportArchive().setupDb();

  // await prepareData();

  var rootUrl = 'http://127.0.0.1:8080';
  await tests(rootUrl);
}
