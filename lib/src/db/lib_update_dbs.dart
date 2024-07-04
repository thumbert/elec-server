library lib.src.db.lib_update_dbs;

import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:elec_server/client/utilities/cmp/cmp.dart';
import 'package:elec_server/client/utilities/ct_supplier_backlog_rates.dart';
import 'package:elec_server/src/db/isoexpress/mra_capacity_bidoffer.dart';
import 'package:elec_server/src/db/isoexpress/zonal_demand.dart';
import 'package:logging/logging.dart';
import 'package:more/more.dart';
import 'package:path/path.dart' as path;
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:timezone/timezone.dart';
import 'lib_prod_archives.dart' as prod;

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

Future<int> updateCompetiveOffersDb(
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

  await archive.getAllUrls();
  for (var month in months) {
    for (var utility in Utility.values) {
      if (externalDownload) {
        await archive.downloadFile(month, utility);
      }
      var file = archive.getFile(month, utility);
      if (file.existsSync()) {
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

Future<void> updateDaEnergyOffersIsone(
    {required List<Month> months,
    bool setUp = false,
    bool download = false}) async {
  assert(months.first.location == IsoNewEngland.location);
  var archive = prod.getDaEnergyOfferArchive();
  if (setUp) await archive.setupDb();
  await archive.dbConfig.db.open();
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
  }
  await archive.dbConfig.db.close();
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
    {required List<Month> months, bool download = true}) async {
  final log = Logger('update ISONE MRA Capacity bids/offers');
  var archive = MraCapacityBidOfferArchive();

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
      log.info('   Created CSV file for ${month.toIso8601String()}');
    } catch (e) {
      log.severe(e.toString());
    }
    // insert it into DuckDb
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

Future<void> updateMorningReport(
    {required List<Month> months, bool download = false}) async {
  var today = Date.today(location: IsoNewEngland.location);
  var archive = prod.getMorningReportArchive();
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
    archive.makeGzFileForMonth(month);
  }
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

Future<void> updateRtEnergyOffersIsone(
    {required List<Month> months, bool download = false}) async {
  var archive = prod.getRtEnergyOfferArchive();
  assert(months.first.location == IsoNewEngland.location);
  for (var month in months) {
    for (var day in month.days()) {
      print('Working on $day');
      var file = archive.getFilename(day);
      if (!file.existsSync()) {
        var res = await baseDownloadUrl(archive.getUrl(day), file,
            username: dotenv.env['ISONE_WS_USER'],
            password: dotenv.env['ISONE_WS_PASSWORD'],
            acceptHeader: 'application/json');
        if (res != 0) throw StateError('Failed to download day $day');
      }
    }
    archive.makeGzFileForMonth(month);
  }
}

Future<void> updateSevenDayCapacityForecast(
    {required List<Month> months}) async {
  var today = Date.today(location: IsoNewEngland.location);
  var archive = prod.getSevenDayCapacityForecastArchive();
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
