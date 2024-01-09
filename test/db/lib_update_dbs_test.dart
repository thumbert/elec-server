import 'dart:async';

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:more/collection.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

Future<void> insertDays(DailyIsoExpressReport archive, List<Date> days) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> tests() async {
  // var days = Date.today(location: UTC).next.previousN(4);
  // var days = Term.parse('1Jan24-4Jan24', UTC).days();

  ///---------------------------------------------------------------
  /// IESO
  // var months = Month.utc(2023, 9).upTo(Month.utc(2023, 12));
  // await updateIesoRtGenerationArchive(months: months);
  // await updateIesoRtZonalDemandArchive(years: [2023, 2024]);

  ///---------------------------------------------------------------
  /// ISONE
  // await updateIsoneHistoricalBtmSolarArchive(Date.utc(2023, 10, 13), setUp: false);
  // await updateIsoneRtSystemLoad5minArchive(days: days, download: true);

  // await insertDays(DaLmpHourlyArchive(), days);
  // await updateDaEnergyOffersIsone(months: [
  //   Month.utc(2023, 1),
  //   Month.utc(2023, 2),
  //   Month.utc(2023, 3),
  //   Month.utc(2023, 4),
  // ]);

  await updateIsoneZonalDemand([2021], download: false);
  // await updateIsoneZonalDemand(IntegerRange(2011, 2021));

  // await updateCmeEnergySettlements(days, setUp: false);

  // var months = Month.utc(2023, 8).upTo(Month.utc(2023, 10));
  // await updateCtSupplierBacklogRatesDb(months: months,
  //     externalDownload: true);

  // var years = IntegerRange(2020, 2024);
  // await updateCmpLoadArchive(years, setUp: true);

  // await updatePolygraphProjects(setUp: false);
}

void main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  dotenv.load('.env/prod.env');

  await tests();
}
