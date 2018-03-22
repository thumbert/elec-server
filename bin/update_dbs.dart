
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_rapid_response_pricing_report.dart';
import 'package:elec_server/src/db/isoexpress/da_cleared_demand_hourly.dart';
import 'package:elec_server/src/db/isoexpress/rt_system_demand_hourly.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';


/// The assumption is that when the ISO publishes an ISO Express report, the
/// report is final.  Manual updates are always possible, but should be avoided.
/// Pitfalls with updating of reports:
/// 1) Daily reports are generated for one day ahead (DA prices), others are
///    generated a few days later (e.g. NCPC reports), or a few months later
///    (e.g. energy offers.)
/// 2) Other reports are have their own weird schedule, FCM reports, FTR,
///    Forward Reserve auctions, etc.
///
main() async {
  initializeTimeZoneSync( getLocationTzdb() );

//  await new DaLmpHourlyArchive().updateDb();
//  await new DaBindingConstraintsReportArchive().updateDb();
//  await new DaClearedDemandReportArchive().updateDb();
//  await new RtSystemDemandReportArchive().updateDb();
//
//  await new NcpcRapidResponsePricingReportArchive().updateDb();

  await new DaEnergyOfferArchive().updateDb();
//  await new DaDemandBidArchive().updateDb();

}
