import 'package:elec_server/api/isoexpress/api_isone_bindingconstraints.dart';
import 'package:elec_server/client/isoexpress/binding_constraints.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:timezone/timezone.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
void tests() async {
  var location = getLocation('America/New_York');
  var shelfRootUrl = dotenv.env['SHELF_ROOT_URL'];
  var archive = DaBindingConstraintsReportArchive();
  group('Binding constraints db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read binding constraints file for 2017-12-31', () async {
      var file = archive.getFilename(Date(2017, 12, 31));
      var data = archive.processFile(file);
      expect(data.first, {
        'Constraint Name': 'BNGW',
        'Contingency Name': 'Interface',
        'Interface Flag': 'Y',
        'Marginal Value': -69.34,
        'hourBeginning': TZDateTime(UTC, 2017, 12, 31, 5),
        'market': 'DA',
        'date': '2017-12-31',
      });
    });
    test('empty file for 2015-02-17', () async {
      var file = archive.getFilename(Date(2015, 2, 17));
      var data = archive.processFile(file);
      expect(data.isEmpty, true);
    });
    test('DA Binding Constraints Report for 2018-07-10 has duplicates',
        () async {
      var file = archive.getFilename(Date(2018, 7, 10));
      var data = archive.processFile(file);
      // 20 entries, only 10 unique
      expect(data.length, 10);
      // await archive.insertData(data);
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
          await api.apiGetDaBindingConstraintsByDay('2017-01-01', '2017-01-02');
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
    test('Get one constraint between two dates', () async {
      var res = await api.apiGetBindingConstraintsByName(
          'DA', 'PARIS   O154          A LN', '2017-01-05', '2017-01-06');
      expect(res.length, 2);
    });
  });
  group('Binding constraints client tests:', () {
    var client = BindingConstraintsApi(http.Client(), rootUrl: shelfRootUrl);
    test('get da binding constraints data for 3 days', () async {
      var interval = Interval(
          TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2017, 1, 3));
      var aux = await client.getDaBindingConstraints(interval);
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
          name, Date(2017, 1, 5), Date(2017, 1, 6));
      expect(aux.length, 2);
    });
  });
}

// void uploadDays() async {
//   var location = getLocation('America/New_York');
//   var archive = DaBindingConstraintsReportArchive();
//   var days = Interval(
//           TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2018, 1, 1))
//       .splitLeft((dt) => Date(dt.year, dt.month, dt.day, location: location));
//   await archive.dbConfig.db.open();
//   for (var day in days) {
//     await archive.downloadDay(day);
//     await archive.insertDay(day);
//   }
//   await archive.dbConfig.db.close();
// }

void main() async {
  initializeTimeZones();

  // await DaBindingConstraintsReportArchive().setupDb();

  // await prepareData();

  dotenv.load('.env/prod.env');
  tests();

  // await uploadDays();
}
