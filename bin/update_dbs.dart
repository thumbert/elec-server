import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/isoexpress/rt_lmp_hourly.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_rapid_response_pricing_report.dart';
import 'package:elec_server/src/db/isoexpress/da_cleared_demand_hourly.dart';
import 'package:elec_server/src/db/isoexpress/rt_system_demand_hourly.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';

updateIsoExpressData() async {
  Month month = new Month(2018, 7);
  List<Date> days = month.splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
  days = days.where((day) => day.isBefore(Date.today().next.next)).toList();

  var archives = [
    new DaLmpHourlyArchive(),
    new RtLmpHourlyArchive(),
    new DaBindingConstraintsReportArchive(),
    new DaClearedDemandReportArchive(),
    new RtSystemDemandReportArchive(),
  ];

  for (var archive in archives) {
    await archive.dbConfig.db.open();
    for (var day in days) {
      if (!await archive.hasDay(day)) {
        await archive.downloadDay(day);
        await archive.insertDay(day);
      }
    }
    await archive.dbConfig.db.close();
  }
}

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
  await initializeTimeZone();

  await updateIsoExpressData();

//  await new DaLmpHourlyArchive().updateDb();
//  await new DaBindingConstraintsReportArchive().updateDb();
//  await new DaClearedDemandReportArchive().updateDb();
//  await new RtSystemDemandReportArchive().updateDb();
//
//  await new NcpcRapidResponsePricingReportArchive().updateDb();

//  await new DaEnergyOfferArchive().updateDb();
//  await new DaDemandBidArchive().updateDb();
}
