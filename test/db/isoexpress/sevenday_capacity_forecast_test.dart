library test.db.isoexpress.sevenday_capacity_forecast_test;

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  final archive = getIsoneSevenDayCapacityForecastArchive();
  group('Seven day capacity forecast tests:', () {
    test('read file for 2024-06-17', () async {
      var file = archive.getFilename(Date.utc(2024, 6, 17));
      var data = archive.processFile(file);
      expect(data.length, 6);
    });
  });
  //
  //
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}
