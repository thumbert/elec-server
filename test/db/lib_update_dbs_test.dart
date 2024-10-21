import 'dart:async';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/db_isone.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:more/collection.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

Future<void> insertDays(DailyIsoExpressReport archive, List<Date> days,
    {bool gzip = false}) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    await archive.downloadDay(day);
    if (gzip) {
      final fileName = archive.getFilename(day).path.removeSuffix('.gz');
      if (!File(fileName).existsSync()) {
        throw StateError('Download failed for $day');
      }
      var res = Process.runSync('gzip', ['-f', fileName],
          workingDirectory: archive.dir);
      if (res.exitCode != 0) {
        throw StateError('GZipping the file for $day has failed!');
      }
    }
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> tests() async {
  // var days = Date.today(location: UTC).next.previousN(4);
  // var days = Term.parse('1Jan24-29Feb24', UTC).days();

  ///---------------------------------------------------------------
  /// IESO
  // var months = Month.utc(2023, 9).upTo(Month.utc(2023, 12));
  // await updateIesoRtGenerationArchive(months: months);
  // await updateIesoRtZonalDemandArchive(years: [2023, 2024]);

  ///---------------------------------------------------------------
  /// ISONE
  // await update
  // await updateIsoneHistoricalBtmSolarArchive(Date.utc(2023, 10, 13), setUp: false);
  // await updateIsoneRtSystemLoad5minArchive(days: days, download: true);

  // await insertDays(DaLmpHourlyArchive(), days, gzip: true);
  final months = Month(2024, 6, location: IsoNewEngland.location)
      .upTo(Month(2024, 6, location: IsoNewEngland.location));
  // await updateIsoneDaLmp(months: months, download: true);
  // await updateIsoneRtLmp(months: months, download: true);
  // await updateIsoneRtLmp5Min(
  //     months: months, ptids: [4000], reportType: 'prelim', download: false);
  // await updateIsoneRtLmp5Min(
  //     months: months, ptids: [4000], reportType: 'final', download: false);


  // await updateIsoneZonalDemand([2021], download: false);
  // await updateIsoneZonalDemand(IntegerRange(2011, 2021));
  // final months = Month(2022, 2, location: IsoNewEngland.location)
  //     .upTo(Month(2022, 12, location: IsoNewEngland.location));
  await updateDaEnergyOffersIsone(months: months, download: true);
  await updateRtEnergyOffersIsone(months: months, download: true);
  // await updateMorningReport(months: months, download: true);
  // await updateIsoneRtReservePrices(months: months, download: true);
  // await updateSevenDayCapacityForecast(months: months);
  // await updateIsoneMraCapacityBidOffer(months: months, download: false);
  // await updateIsoneMraCapacityResults(months: months, download: false);

  // await updateCmeEnergySettlements(days, setUp: false);

  // var months = Month.utc(2023, 8).upTo(Month.utc(2023, 10));
  // await updateCtSupplierBacklogRatesDb(months: months,
  //     externalDownload: true);

  // var years = IntegerRange(2020, 2024);
  // await updateCmpLoadArchive(years, setUp: true);

  // await updatePolygraphProjects(setUp: false);

  ///------------------------------------------------------------------
  /// NYISO
  // await updateEnergyOffersNyiso(months: months, download: true);

  ///------------------------------------------------------------------
  /// Weather
  // await insertNoaaTemperatures(download: true);
  // await insertNormalTemperatures();
}

void main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name} (${record.time.toString().substring(0, 19)}) ${record.message}');
  });

  dotenv.load('.env/prod.env');

  await tests();
}
