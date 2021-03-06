import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_dispatch_lost_opportunity_cost_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_economic_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_generator_performance_audit_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_lscpr_report.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/isoexpress/rt_lmp_hourly.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_rapid_response_pricing_report.dart';
import 'package:elec_server/src/db/isoexpress/da_cleared_demand_hourly.dart';
import 'package:elec_server/src/db/isoexpress/rt_system_demand_hourly.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';

Future<void> updateDailyArchive(DailyIsoExpressReport archive, List<Date> days) async {
    print('Updating archive ${archive.reportName}');
    // await archive.setupDb();
    await archive.dbConfig.db.open();
    for (var day in days) {
      await archive.downloadDay(day);
      await archive.insertDay(day);
    }
    await archive.dbConfig.db.close();
}

void main() async {
  await initializeTimeZone();
  var days = Month.utc(2018, 1).days();

  await updateDailyArchive(NcpcEconomicReportArchive(), days);
  await updateDailyArchive(NcpcLscprReportArchive(), days);
  await updateDailyArchive(NcpcDlocReportArchive(), days);
  await updateDailyArchive(NcpcGpaReportArchive(), days);
  await updateDailyArchive(NcpcRapidResponsePricingReportArchive(), days);

}
