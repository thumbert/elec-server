library test.db.nyiso.binding_constraints_test;

import 'package:elec_server/src/db/lib_nyiso_report.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() async {
  group('NYISO report tests:', () {
    test('convert timestamp to UTC', () async {
      expect(NyisoReport.parseTimestamp('01/01/2020 05:00', 'EST'),
          TZDateTime.utc(2020, 1, 1, 10));
      expect(NyisoReport.parseTimestamp('03/08/2020 01:00', 'EST'),
          TZDateTime.utc(2020, 3, 8, 6));
      expect(NyisoReport.parseTimestamp('03/08/2020 03:00', 'EDT'),
          TZDateTime.utc(2020, 3, 8, 7));
      expect(NyisoReport.parseTimestamp('11/01/2020 01:00', 'EDT'),
          TZDateTime.utc(2020, 11, 1, 5));
      expect(NyisoReport.parseTimestamp('11/01/2020 01:00', 'EST'),
          TZDateTime.utc(2020, 11, 1, 6));
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
