import 'dart:io';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
void tests() async {
  group('DA binding constraints report', () {
    var archive = DaBindingConstraintsReportArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
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
  await initializeTimeZone();

  // print(Platform.environment['HOME']);
  dotenv.load('${Platform.environment['HOME']}/.env/isone.env');

  // await DaBindingConstraintsReportArchive().setupDb();

  // await prepareData();

  await tests();

  // await uploadDays();
}
