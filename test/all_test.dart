


import 'package:timezone/standalone.dart';
import 'utils/iso_timestamp_test.dart' as isoTimestamp;
import 'db/isone_ptids_test.dart' as apiPtids;

import 'client/isoexpress/binding_constraints_test.dart' as bc;
import 'client/isoexpress/da_energy_offer_test.dart' as daoffers;
import 'client/isoexpress/dalmp_test.dart' as dalmp;
import 'client/other/ptids_test.dart' as ptid;


main() async {
  await initializeTimeZone();

  isoTimestamp.testParseIsoTimestamp();
  apiPtids.apiTest();

  var rootUrl = 'http://localhost:8080/';

  /// Client tests
  bc.tests();
  dalmp.tests(rootUrl);
  daoffers.tests();
  ptid.tests();

}