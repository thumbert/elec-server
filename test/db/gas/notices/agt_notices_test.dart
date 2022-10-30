library test.db.gas.notices.agt_notices_test;

import 'dart:convert';
import 'package:elec_server/src/db/gas/notices/agt_notices.dart';
import 'package:elec_server/src/db/nyiso/btm_solar_actual_mw.dart';
import 'package:elec_server/src/db/nyiso/btm_solar_forecast_mw.dart';
import 'package:elec_server/src/db/nyiso/rt_zonal_load_hourly.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';


/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = AgtNoticesArchive();
  group('AGT critical notices tests:', () {
    // setUp(() async => await archive.db.open());
    // tearDown(() async => await archive.db.close());
    test('read current critical ids', () async {
      var uris = await archive.getUris(pipeline: 'AG', type: 'CRI');
      // await archive.saveUrisToDisk(uris);
      await archive.savePdfToDisk(Month.utc(2020,1).upTo(Month.utc(2022, 8)));
      expect(uris.length > 12, true);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
