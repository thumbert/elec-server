import 'dart:async';

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:more/collection.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

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
  // var days = Term.parse('24May22-31May22', UTC).days();

  // var months = Month.utc(2020, 1).upTo(Month.utc(2023, 9));
  // await updateIesoRtGenerationArchive(months: months);
  // await updateIesoRtZonalDemandArchive(years: [2023]);


  // await insertDays(DaLmpHourlyArchive(), days);
  // await updateDaEnergyOffersIsone(months: [
  //   Month.utc(2023, 1),
  //   Month.utc(2023, 2),
  //   Month.utc(2023, 3),
  //   Month.utc(2023, 4),
  // ]);


  // var years = IntegerRange(2013, 2023);
  // var days = Term.parse('Cal21', UTC).days();
  // await insertDays(DaLmpHourlyArchive(), days);
  // var days = Term.parse('24May22-31May22', UTC).days();
  // await insertDays(DaLmpHourlyArchive(), days);

  // await updateCmeEnergySettlements(days, setUp: false);

  // var months = Month.utc(2022, 2).upTo(Month.utc(2023, 7));
  // await updateCtSupplierBacklogRatesDb(months: months,
  //     // setUp: true,
  //     externalDownload: false);

  var years = IntegerRange(2020, 2024);
  await updateCmpLoadArchive(years, setUp: true);

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

  ///
  /// See bin/setup_db.dart on how to update a database
  ///
}
