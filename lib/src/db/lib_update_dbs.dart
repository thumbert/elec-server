import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:elec_server/client/utilities/cmp/cmp.dart';
import 'package:elec_server/client/utilities/ct_supplier_backlog_rates.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
// import 'package:elec_server/src/db/isoexpress/mra_capacity_bidoffer.dart';
import 'package:elec_server/src/db/isoexpress/zonal_demand.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:timezone/timezone.dart';
import 'lib_prod_archives.dart' as prod;

final log = Logger('Update dbs');

Future<void> updateCmeEnergySettlements(List<Date> days,
    {bool setUp = false}) async {
  var archive = prod.getCmeEnergySettlementsArchive();
  if (setUp) await archive.setupDb();
  await archive.dbConfig.db.open();
  for (var asOfDate in days) {
    var file = archive.getFilename(asOfDate);
    // downloading the file and zipping it handled separately
    if (file.existsSync()) {
      var data = archive.processFile(file);
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}

/// Files need to be downloaded by hand from
/// https://www.maine.gov/mpuc/regulated-utilities/electricity/rfps/standard-offer
/// and saved as a csv file (see the archive.)
///
Future<void> updateCmpLoadArchive(List<int> years, {bool setUp = false}) async {
  var archive = prod.getCmpLoadArchive();
  if (setUp) await archive.setupDb();
  await archive.dbConfig.db.open();
  for (var year in years) {
    // for (var customerClass in CmpCustomerClass.values) {
    for (var customerClass in [
      CmpCustomerClass.residentialAndSmallCommercial
    ]) {
      var file = archive.getFile(
          year: year, customerClass: customerClass, settlementType: 'final');
      if (file.existsSync()) {
        var data = archive.processFile(
            year: year, customerClass: customerClass, settlementType: 'final');
        // print(data);
        await archive.insertData(data);
      }
    }
  }
  await archive.dbConfig.db.close();
}

Future<int> updateCompetitiveOffersDb(
    {List<Date>? days,
    List<String>? states,
    bool externalDownload = true}) async {
  days ??= [Date.today(location: UTC)];
  states ??= ['CT', 'MA'];
  var status = 0;

  var archive = prod.getRetailSuppliersOffersArchive();
  if (externalDownload) {
    await archive.saveCurrentRatesToFile();
  }
  await archive.setupDb();
  await archive.dbConfig.db.open();

  for (var date in days) {
    if (states.contains('CT')) {
      var file = File(path.join(archive.dir, '${date.toString()}_ct.json'));
      if (file.existsSync()) {
        var data = archive.processFile(file);
        await archive.insertData(data);
      } else {
        print('No $date file for CT to process');
        status = 1;
      }
    }
    if (states.contains('MA')) {
      var file = File(
          path.join(archive.dir, '${date.toString()}_ma_residential.json'));
      if (file.existsSync()) {
        var data = archive.processFile(file);
        await archive.insertData(data);
      } else {
        print('No $date file for MA to process');
        status = 1;
      }
    }
  }
  await archive.dbConfig.db.close();

  return status;
}

Future<void> updateCtSupplierBacklogRatesDb(
    {required List<Month> months,
    bool externalDownload = true,
    bool setUp = false}) async {
  var archive = prod.getCtSupplierBacklogRatesArchive();
  if (setUp) await archive.setupDb();
  await archive.dbConfig.db.open();

  if (externalDownload) {
    await archive.getAllUrls();
    for (var month in months) {
      for (var utility in Utility.values) {
        await archive.downloadFile(month, utility);
      }
    }
    print('Xlsx files downloaded');
  }

  for (var month in months) {
    for (var utility in Utility.values) {
      var file = archive.getFile(month, utility);
      if (file.existsSync()) {
        print('Processing file for $utility $month');
        var data = archive.processFile(file);
        await archive.insertData(data);
      } else {
        print('No file for $utility $month to process!');
      }
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> updateDailyArchive(
    DailyIsoExpressReport archive, List<Date> days) async {
  print('Updating archive ${archive.reportName}');
  // await archive.setupDb();
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> updateIsoneDaEnergyOffers(
    {required List<Month> months, bool download = false}) async {
  assert(months.first.location == IsoNewEngland.location);
  var archive = prod.getIsoneDaEnergyOfferArchive();
  for (var month in months) {
    var days = month.days();
    // days = [Date(2025, 6, 30, location: IsoNewEngland.location)];
    for (var day in days) {
      if (download) {
        await archive.downloadDay(day);
      }
    }
    archive.makeGzFileForMonth(month);
    archive.updateDuckDb(
        months: [month],
        pathDbFile:
            '${Platform.environment['HOME']}/Downloads/Archive/DuckDB/isone/masked_energy_offers.duckdb');
  }
}

Future<void> updateIesoRtGenerationArchive(
    {required List<Month> months, bool setUp = false}) async {
  var archive = prod.getIesoRtGenerationArchive();
  if (setUp) await archive.setupDb();

  await archive.dbConfig.db.open();
  for (var month in months) {
    var url = archive.getUrl(month);
    var file = archive.getFilename(month, extension: 'csv');
    await archive.downloadUrl(url, file, zipFile: true);
    file = archive.getFilename(month, extension: 'zip');
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> updateIesoRtZonalDemandArchive(
    {required List<int> years, bool setUp = false}) async {
  var archive = prod.getIesoRtZonalDemandArchive();
  if (setUp) await archive.setupDb();

  await archive.dbConfig.db.open();
  for (var year in years) {
    var url = archive.getUrl(year);
    var file = archive.getFilename(year);
    await archive.downloadUrl(url, file);
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> updateIsoneDaBindingConstraints(List<Date> days,
    {bool setup = false, bool externalDownload = true}) async {
  var archive = DaBindingConstraintsReportArchive();
  if (setup) await archive.setupDb();
  await archive.dbConfig.db.open();
  for (var day in days) {
    if (externalDownload) await archive.downloadDay(day);
    var data = archive.processFile(archive.getFilename(day));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> updateIsoneRtSystemLoad5minArchive(
    {required List<Date> days,
    bool setUp = false,
    bool download = true}) async {
  var archive = prod.getRtSystemLoad5minArchive();
  if (setUp) await archive.setupDb();

  await archive.dbConfig.db.open();
  for (var day in days) {
    if (download) {
      await archive.downloadDay(day);
      final jsonFile =
          '${archive.dir}/${day.year}/isone_systemload_5min_$day.json';
      if (!File(jsonFile).existsSync()) {
        throw StateError('Download failed for $day');
      }
      var res =
          Process.runSync('gzip', [jsonFile], workingDirectory: archive.dir);
      if (res.exitCode != 0) {
        throw StateError('GZipping the file for $day has failed!');
      }
    }
    var data = archive.processFile(archive.getFilename(day));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

/// File need to be downloaded by hand
Future<void> updateIsoneHistoricalBtmSolarArchive(Date asOfDate,
    {bool setUp = false}) async {
  var archive = prod.getIsoneHistoricalBtmSolarArchive();
  if (setUp) await archive.setupDb();
  await archive.dbConfig.db.open();
  final data = archive.processFile(asOfDate);
  await archive.insertData(data);
  await archive.dbConfig.db.close();
}

Future<void> updateIsoneMraCapacityBidOffer(
    {required List<Month> months, required bool download}) async {
  final log = Logger('update ISONE MRA Capacity bids/offers');
  final archive = prod.getIsoneMraBidOfferArchive();

  log.info('Updating ISONE MRA bids/offers');
  for (var month in months) {
    log.info('Working on month ${month.toIso8601String()}');
    var file = archive.getFilename(month);
    var url = archive.getUrl(month);
    if (download) {
      await baseDownloadUrl(url, file,
          acceptHeader: 'application/json',
          username: dotenv.env['ISONE_WS_USER'],
          password: dotenv.env['ISONE_WS_PASSWORD']);
      log.info('   Downloaded JSON file for ${month.toIso8601String()}');
    }
    try {
      archive.makeCsvFileForDuckDb(month);
      log.info('   Created CSV file for month ${month.toIso8601String()}');
    } catch (e) {
      log.severe(e.toString());
    }
    archive.updateDuckDb(
        months: [month],
        pathDbFile:
            '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/Capacity/isone/mra.duckdb');
  }
}

Future<void> updateIsoneDaLmp(
    {required List<Month> months, required bool download}) async {
  assert(months.first.location == IsoNewEngland.location);
  var archive = prod.getIsoneDaLmpArchive();
  for (var month in months) {
    for (var day in month.days()) {
      if (download) {
        await archive.downloadDay(day);
      }
      // var file = archive.getFilename(day);
      // var data = archive.processFile(file);
      // await archive.insertData(data);
    }
    // archive.makeGzFileForMonth(month);
    // archive.updateDuckDb(
    //     months: [month],
    //     pathDbFile:
    //         '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/energy_offers.duckdb');
  }
}

Future<void> updateIsoneDemandBids(
    {required List<Month> months, required bool download}) async {
  assert(months.first.location == IsoNewEngland.location);
  var archive = prod.getIsoneDemandBidsArchive();
  for (var month in months) {
    var days = month.days();
    // days = [Date(2024, 12, 31, location: IsoNewEngland.location)];
    for (var day in days) {
      if (download) {
        if (!archive.skipDays.contains(day)) {
          await archive.downloadDay(day);
        }
      }
    }
    archive.makeGzFileForMonth(month);
    archive.updateDuckDb(months: [month], pathDbFile: archive.duckdbPath);
  }
}

Future<void> updateIsoneMonthlyAssetNcpc(
    {required List<Month> months, required bool download}) async {
  assert(months.first.location == IsoNewEngland.location);
  var archive = prod.getIsoneMonthlyAssetNcpcArchive();
  await archive.dbConfig.db.open();
  for (var month in months) {
    await archive.downloadMonth(month);
    var data = archive.processFile(archive.getFilename(month));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> updateIsoneMorningReport(
    {required List<Month> months, bool download = false}) async {
  var today = Date.today(location: IsoNewEngland.location);
  var archive = prod.getIsoneMorningReportArchive();
  for (var month in months) {
    for (var day in month.days()) {
      print('Working on $day');
      if (day.isAfter(today)) continue;
      var file = archive.getFilename(day);
      if (!file.existsSync() || download) {
        var res = await baseDownloadUrl(archive.getUrl(day), file,
            username: dotenv.env['ISONE_WS_USER'],
            password: dotenv.env['ISONE_WS_PASSWORD'],
            acceptHeader: 'application/json');
        if (res != 0) throw StateError('Failed to download');
      }
    }
    // archive.makeGzFileForMonth(month);
    archive.updateDuckDb(month);
  }
}

//
Future<void> updateIsoneMraCapacityResults(
    {required List<Month> months, required bool download}) async {
  final log = Logger('update ISONE MRA capacity results');
  final archive = prod.getIsoneMraResultsArchive();

  log.info('Updating ISONE MRA results');
  for (var month in months) {
    log.info('Working on month ${month.toIso8601String()}');
    var file = archive.getFilename(month);
    var url = archive.getUrl(month);
    if (download) {
      await baseDownloadUrl(url, file,
          acceptHeader: 'application/json',
          username: dotenv.env['ISONE_WS_USER'],
          password: dotenv.env['ISONE_WS_PASSWORD']);
      log.info('   Downloaded JSON file for ${month.toIso8601String()}');
    }
    archive.makeCsvFileForDuckDb(month);
    log.info('   Created CSV files for month ${month.toIso8601String()}');
    archive.updateDuckDb(
        months: [month],
        pathDbFile:
            '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/Capacity/isone/mra.duckdb');
  }
}

Future<void> updateIsoneRtEnergyOffers(
    {required List<Month> months, bool download = false}) async {
  var archive = prod.getIsoneRtEnergyOfferArchive();
  assert(months.first.location == IsoNewEngland.location);
  for (var month in months) {
    for (var day in month.days()) {
      if (download) {
        await archive.downloadDay(day);
      }
    }
    archive.makeGzFileForMonth(month);
    archive.updateDuckDb(
        months: [month],
        pathDbFile:
            '${Platform.environment['HOME']}/Downloads/Archive/DuckDB/isone/masked_energy_offers.duckdb');
  }
}

Future<void> updateIsoneRtReservePrices(
    {required List<Month> months, required bool download}) async {
  var today = Date.today(location: IsoNewEngland.location);
  var archive = prod.getIsoneRtReservePriceArchive();

  for (var month in months) {
    log.info('Working on month ${month.toIso8601String()}');
    for (var day in month.days()) {
      log.info('   Working on $day');
      if (day.isAfter(today)) continue;
      var file = archive.getFilename(day);
      if (!file.existsSync() || download) {
        var res = await baseDownloadUrl(archive.getUrl(day), file,
            username: dotenv.env['ISONE_WS_USER'],
            password: dotenv.env['ISONE_WS_PASSWORD'],
            acceptHeader: 'application/json');
        if (res != 0) throw StateError('Failed to download');
      }
    }
    archive.makeGzFileForMonth(month);
    log.info('   Created CSV file for month ${month.toIso8601String()}');
    archive.updateDuckDb(
        months: [month], pathDbFile: '${archive.dir}/rt_reserve_price.duckdb');
  }
}

Future<void> updateIsoneRtLmp(
    {required List<Month> months, required bool download}) async {
  assert(months.first.location == IsoNewEngland.location);
  var archive = prod.getIsoneRtLmpArchive();
  for (var month in months) {
    for (var day in month.days()) {
      if (download) {
        await archive.downloadDay(day);
      }
      // var file = archive.getFilename(day);
      // var data = archive.processFile(file);
      // await archive.insertData(data);
    }
    archive.makeGzFileForMonth(month);
    // archive.updateDuckDb(
    //     months: [month],
    //     pathDbFile:
    //         '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/energy_offers.duckdb');
  }
}

Future<void> updateIsoneRtLmp5Min(
    {required List<Month> months,
    required List<int> ptids,
    required String reportType,
    required bool download}) async {
  assert(months.first.location == IsoNewEngland.location);
  var archive = prod.getIsoneRtLmp5MinArchive();
  for (var ptid in ptids) {
    for (var month in months) {
      for (var day in month.days()) {
        if (download) {
          await archive.downloadDay(day, type: reportType, ptid: ptid);
        }
      }
      archive.makeGzFileForMonth(month, type: reportType, ptid: ptid);
    }
    archive.updateDuckDb(
        ptid: ptid,
        reportType: reportType,
        months: months,
        pathDbFile:
            '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/rt_lmp5min.duckdb');
  }
}

Future<void> updateIsoneSevenDayCapacityForecast(
    {required List<Month> months}) async {
  var today = Date.today(location: IsoNewEngland.location);
  var archive = prod.getIsoneSevenDayCapacityForecastArchive();
  for (var month in months) {
    for (var day in month.days()) {
      print('Working on $day');
      if (day.isAfter(today)) continue;
      var file = archive.getFilename(day);
      if (!file.existsSync()) {
        var res = await baseDownloadUrl(archive.getUrl(day), file,
            username: dotenv.env['ISONE_WS_USER'],
            password: dotenv.env['ISONE_WS_PASSWORD'],
            acceptHeader: 'application/json');
        if (res != 0) throw StateError('Failed to download');
      }
    }
    archive.makeGzFileForMonth(month);
  }
}

Future<void> updateIsoneZonalDemand(List<int> years,
    {bool setUp = false, bool download = false}) async {
  var archive = ZonalDemandArchive();
  if (setUp) {
    await ZonalDemandArchive().setupDb();
  }

  if (download) {
    for (var year in years) {
      // download the files and convert to xlsx before 2017
      await archive.downloadYear(year);
    }
  }

  await archive.dbConfig.db.open();
  for (var year in years) {
    print('Year: $year');
    var file = archive.getFilename(year);
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> updateNyisoEnergyOffers(
    {required List<Month> months,
    bool setUp = false,
    bool download = false}) async {
  assert(months.first.location == IsoNewEngland.location);
  var archive = prod.getNyisoEnergyOfferArchive();
  if (setUp) await archive.setupDb();
  await archive.dbConfig.db.open();
  for (var month in months) {
    log.info('Working on month ${month.toIso8601String()}');
    if (download) {
      await archive.downloadMonth(month);
    }
    var file = archive.getCsvFile(month.startDate);
    var data = archive.processFile(file);
    await archive.insertData(data);
    final res = archive.makeGzFileForMonth(month);
    archive.updateDuckDb(
        months: [month],
        pathDbFile:
            '${Platform.environment['HOME']}/Downloads/Archive/Nyiso/nyiso_energy_offers.duckdb');
    if (res != 0) {
      throw StateError("Failed to update DuckDB for month $month");
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> updatePolygraphProjects({bool setUp = false}) async {
  var archive = prod.getPolygraphArchive();

  /// currently, files are written by quiver/test/model/polygraph/other/serde_test.dart
  var files = archive.dir
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.json'))
      .toList();

  var projects = [for (var file in files) archive.readFile(file)];

  await archive.setupDb();
  await archive.dbConfig.db.open();
  for (var project in projects) {
    await archive.insertData(project);
  }
  await archive.dbConfig.db.close();
}
