import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

import 'client/marks/curves/curve_id_test.dart' as curve_id;
import 'db/cme/cme_energy_settlements_test.dart' as cme;
import 'db/ieso/rt_generation_test.dart' as ieso_rtgen;
import 'db/ieso/rt_zonal_demand_test.dart' as ieso_rtzd;
import 'db/isoexpress/da_binding_constraints_report_test.dart' as bc;
import 'db/isoexpress/da_energy_offer_test.dart' as energy_offers;
import 'db/isoexpress/da_demand_bid_test.dart' as demand_bids;
import 'db/isoexpress/da_congestion_compact_test.dart' as da_congestion;
import 'db/isoexpress/da_lmp_hourly_test.dart' as dalmp;
import 'db/isoexpress/rt_lmp_hourly_test.dart' as rtlmp;
import 'db/isoexpress/fwdres_auction_results_test.dart' as fwdres;
import 'db/isoexpress/monthly_asset_ncpc_test.dart' as monthly_asset_ncpc;
import 'db/isoexpress/regulation_requirement_test.dart'
    as regulation_requirement;
import 'db/isoexpress/wholesale_load_cost_report_test.dart'
    as wholesale_load_cost_report;
import 'db/isone_ptids_test.dart' as ptids;
import 'db/isone/masked_ids_test.dart' as masked_ids;

import 'db/lib_mis_reports_test.dart' as mis;
import 'db/lib_nyiso_report_test.dart' as lib_nyiso_report;
import 'db/marks/forward_marks_test.dart' as forward_marks;
import 'db/mis/sd_arrawdsum_test.dart' as sd_arrawdsum;
import 'db/mis/sd_rtload_test.dart' as sd_rtload;
import 'db/mis/sr_dalocsum_test.dart' as sr_dalocsum;
import 'db/mis/sr_rtlocsum_test.dart' as sr_rtlocsum;
import 'db/mis/tr_sch2tp_test.dart' as trsch2;
import 'db/mis/tr_sch3p2_test.dart' as trsch3;
import 'db/nyiso/binding_constraints_test.dart' as nyiso_binding_constraints;
import 'db/nyiso/da_congestion_compact_test.dart' as nyiso_dacongestion;
import 'db/nyiso/da_energy_offer_test.dart' as nyiso_daenergyoffer;
import 'db/nyiso/da_lmp_hourly_test.dart' as nyiso_dalmp;
import 'db/nyiso/rt_lmp_hourly_test.dart' as nyiso_rtlmp;
import 'db/nyiso/masked_ids_test.dart' as nyiso_masked_ids;
import 'db/nyiso/nyiso_ptid_test.dart' as nyiso_ptids;
import 'db/pjm/pjm_ptid_test.dart' as pjm_ptids;
import 'db/polygraph/polygraph_archive_test.dart' as polygraph;
import 'db/utilities/cmp/load_cmp_test.dart' as load_cmp;
import 'db/utilities/ct_supplier_backlog_rates_test.dart' as ct_retail_suppliers;
import 'db/utilities/retail_offers/retail_suppliers_offers_archive_test.dart'
    as retail_offers;
import 'db/weather/noaa_daily_summary_test.dart' as noaa_daily_summary;

import 'utils/iso_timestamp_test.dart' as iso_timestamp;
import 'utils/iterable_extensions_test.dart' as iterable_ext;
import 'utils/parse_custom_integer_range_test.dart' as parse_int_range;
import 'utils/term_cache_test.dart' as term_cache;
import 'utils/to_csv_test.dart' as to_csv;

Future<void> main() async {
  initializeTimeZones();
  DbProd();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;

  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  /// db tests
  await bc.tests(rootUrl);
  await cme.tests(rootUrl);
  await ct_retail_suppliers.tests(rootUrl);
  await ieso_rtgen.tests(rootUrl);
  await ieso_rtzd.tests(rootUrl);
  await da_congestion.tests(rootUrl);
  await dalmp.tests(rootUrl);
  await demand_bids.tests();
  await energy_offers.tests(rootUrl);
  await fwdres.tests(rootUrl);
  lib_nyiso_report.tests();
  await load_cmp.tests();
  await masked_ids.tests(rootUrl);
  await monthly_asset_ncpc.tests(rootUrl);
  await nyiso_binding_constraints.tests(rootUrl);
  await nyiso_dalmp.tests(rootUrl);
  await nyiso_dacongestion.tests(rootUrl);
  await nyiso_daenergyoffer.tests(rootUrl);
  await nyiso_rtlmp.tests(rootUrl);
  await nyiso_masked_ids.tests(rootUrl);
  await nyiso_ptids.tests(rootUrl);

  await pjm_ptids.tests(rootUrl);
  await polygraph.tests(rootUrl);
  await ptids.tests(rootUrl);
  await regulation_requirement.tests(rootUrl);
  await retail_offers.tests(rootUrl);
  await rtlmp.tests();

  sd_arrawdsum.tests(rootUrl);
  sd_rtload.tests();
  sr_dalocsum.tests(rootUrl);
  sr_rtlocsum.tests();
  trsch2.tests();
  trsch3.tests();

  await noaa_daily_summary.tests(rootUrl);

  /// Client tests
  await curve_id.tests(rootUrl);
  await forward_marks.tests(rootUrl);

  mis.tests();
  wholesale_load_cost_report.tests();

  /// Utils tests
  iterable_ext.tests();
  iso_timestamp.tests();
  parse_int_range.tests();
  term_cache.tests();
  to_csv.tests();
}
