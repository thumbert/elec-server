


import 'package:timezone/standalone.dart';
import 'utils/iso_timestamp_test.dart' as isoTimestamp;
import 'db/isone_ptids_test.dart' as apiPtids;
import 'api/isone_bindingconstraints_test.dart' as apiBindingConstraints;

main() async {
  await initializeTimeZone();

  isoTimestamp.testParseIsoTimestamp();
  apiBindingConstraints.apiTest();
  apiPtids.apiTest();



}