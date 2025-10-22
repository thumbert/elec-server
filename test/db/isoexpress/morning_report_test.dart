import 'package:date/date.dart';
import 'package:elec_server/client/isoexpress/morning_report.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  final archive = getIsoneMorningReportArchive();
  group('ISONE morning report tests:', () {
    test('read file for 2024-01-01', () async {
      var file = archive.getFilename(Date.utc(2024, 1, 1));
      var data = archive.processFile(file);
      expect(data.length, 2);
      var columns = data.first.toJson().keys.toList();
      expect(columns.length, MorningReport.colnames.length);
      print(columns.map((e) => "$e ,").join('\n'));
    });
    test('read file for 2024-05-31', () async {
      // two new fields for geo magnetic disturbance
      var file = archive.getFilename(Date.utc(2024, 5, 31));
      var data = archive.processFile(file);
      expect(data.length, 2);
      var columns = data.first.toJson().keys.toList();
      expect(columns.length, MorningReport.colnames.length);
    });
    test('read file for 2020-09-28', () async {
      var file = archive.getFilename(Date.utc(2020, 9, 28));
      var data = archive.processFile(file);
      expect(data.length, 2);
      var columns = data.first.toJson().keys.toList();
      expect(columns.length, MorningReport.colnames.length);
    });
    test('read file for 2023-06-16', () async {
      var file = archive.getFilename(Date.utc(2023, 6, 16));
      var data = archive.processFile(file);
      expect(data.length, 2);
      var columns = data.first.toJson().keys.toList();
      expect(columns.length, MorningReport.colnames.length);
    });
  });
  //
  //
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}
