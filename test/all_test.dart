


import 'package:timezone/standalone.dart';
import 'db/isone_ptids_test.dart' as api_ptids;
import 'db/lib_mis_reports_test.dart' as mis;
import 'client/isoexpress/binding_constraints_test.dart' as bc;
import 'client/isoexpress/da_energy_offer_test.dart' as daoffers;
import 'client/isoexpress/dalmp_test.dart' as dalmp;
import 'client/isoexpress/system_demand_test.dart' as sysdem;
import 'client/other/ptids_test.dart' as ptid;
import 'utils/iso_timestamp_test.dart' as iso_timestamp;
import 'utils/parse_custom_integer_range_test.dart' as parse_int_range;
import 'utils/term_cache_test.dart' as term_cache;
import 'utils/to_csv_test.dart' as to_csv;

void main() async {
  await initializeTimeZone();

  api_ptids.apiTest();

  var rootUrl = 'http://localhost:8080/';

  /// Client tests
  bc.tests();
  dalmp.tests(rootUrl);
  daoffers.tests();
//  sysdem.tests(rootUrl);
//  ptid.tests();
  mis.tests();

  /// Utils tests
  iso_timestamp.testParseIsoTimestamp();
  parse_int_range.tests();
  term_cache.tests();
  to_csv.tests();

}