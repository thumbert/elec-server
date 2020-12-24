import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';

import 'client/isoexpress/binding_constraints_test.dart' as bc;
import 'client/isoexpress/da_energy_offer_test.dart' as daoffers;
import 'client/isoexpress/dalmp_test.dart' as dalmp;
import 'client/marks/curves/curve_id_test.dart' as curve_id;
import 'client/other/ptids_test.dart' as ptid;
import 'db/isoexpress/wholesale_load_cost_report_test.dart'
    as wholesale_load_cost_report;
import 'db/isone_ptids_test.dart' as api_ptids;
import 'db/lib_mis_reports_test.dart' as mis;
import 'db/marks/forward_marks_test.dart' as forward_marks;
import 'db/mis/sr_dalocsum_test.dart' as sr_dalocsum;
import 'db/mis/sr_rtlocsum_test.dart' as sr_rtlocsum;
import 'db/mis/tr_sch2tp_test.dart' as trsch2;
import 'db/mis/tr_sch3p2_test.dart' as trsch3;
import 'db/risk_system/calculator_archive_test.dart' as calculators;
import 'utils/iso_timestamp_test.dart' as iso_timestamp;
import 'utils/parse_custom_integer_range_test.dart' as parse_int_range;
import 'utils/term_cache_test.dart' as term_cache;
import 'utils/to_csv_test.dart' as to_csv;

void main() async {
  await initializeTimeZones();
  var rootUrl = 'http://localhost:8080/';
  DbProd();

  Logger.root.level = Level.WARNING; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  api_ptids.tests();

  /// db tests
  sr_dalocsum.tests();
  sr_rtlocsum.tests();
  trsch2.tests();
  trsch3.tests();
  calculators.tests(rootUrl);

  /// Client tests
  bc.tests();
  dalmp.tests(rootUrl);
  daoffers.tests();
  curve_id.tests(rootUrl);
  forward_marks.tests(rootUrl);
//  sysdem.tests(rootUrl);
  ptid.tests();
  mis.tests();
  wholesale_load_cost_report.tests();

  /// Utils tests
  iso_timestamp.tests();
  parse_int_range.tests();
  term_cache.tests();
  to_csv.tests();
}
