


import 'package:timezone/standalone.dart';
import 'utils/iso_timestamp_test.dart' as isoTimestamp;
import 'db/isone_ptids_test.dart' as apiPtids;
import 'db/lib_mis_reports_test.dart' as mis;
import 'client/isoexpress/binding_constraints_test.dart' as bc;
import 'client/isoexpress/da_energy_offer_test.dart' as daoffers;
import 'client/isoexpress/dalmp_test.dart' as dalmp;
import 'client/isoexpress/system_demand_test.dart' as sysdem;
import 'client/other/ptids_test.dart' as ptid;


import 'utils/to_csv_test.dart' as toCsv;

main() async {
  await initializeTimeZone();

  isoTimestamp.testParseIsoTimestamp();
  apiPtids.apiTest();

  var rootUrl = 'http://localhost:8080/';

  /// Client tests
  bc.tests();
  dalmp.tests(rootUrl);
  daoffers.tests();
//  sysdem.tests(rootUrl);
//  ptid.tests();
  mis.tests();

  toCsv.tests();

}