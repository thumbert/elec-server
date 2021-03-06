import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

import 'client/marks/curves/curve_id_test.dart' as curve_id;
import 'db/isoexpress/da_binding_constraints_report_test.dart' as bc;
import 'db/isoexpress/da_energy_offer_test.dart' as energy_offers;
import 'db/isoexpress/da_demand_bid_test.dart' as demand_bids;
import 'db/isoexpress/da_lmp_hourly_test.dart' as dalmp;
import 'db/isoexpress/regulation_requirement_test.dart'
    as regulation_requirement;
import 'db/isoexpress/wholesale_load_cost_report_test.dart'
    as wholesale_load_cost_report;
import 'db/isone_ptids_test.dart' as ptids;
import 'db/lib_mis_reports_test.dart' as mis;
import 'db/marks/forward_marks_test.dart' as forward_marks;
import 'db/mis/sd_arrawdsum_test.dart' as sd_arrawdsum;
import 'db/mis/sd_rtload_test.dart' as sd_rtload;
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
  initializeTimeZones();
  DbProd();
  dotenv.load('.env/prod.env');
  // var rootUrl = 'http://127.0.0.1:8080';
  var rootUrl = dotenv.env['ROOT_URL']!;

  // var keys = ['a', 'b', 'c'];
  // var xs = [1, null, 3];
  // var m = {for (var i=0; i<3; i++) keys[i] : xs[i] as num?};
  // var m2 = Map.fromIterables(keys, xs);

  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  /// db tests
  bc.tests(rootUrl);
  calculators.tests(rootUrl);
  dalmp.tests(rootUrl);
  demand_bids.tests();
  energy_offers.tests(rootUrl);
  ptids.tests(rootUrl);
  regulation_requirement.tests(rootUrl);
  sd_arrawdsum.tests(rootUrl);
  sd_rtload.tests();
  sr_dalocsum.tests(rootUrl);
  sr_rtlocsum.tests();
  trsch2.tests();
  trsch3.tests();

  /// Client tests
  curve_id.tests(rootUrl);
  forward_marks.tests(rootUrl);
//  sysdem.tests(rootUrl);
  mis.tests();
  wholesale_load_cost_report.tests();

  /// Utils tests
  iso_timestamp.tests();
  parse_int_range.tests();
  term_cache.tests();
  to_csv.tests();
}
