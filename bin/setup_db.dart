import 'dart:io';

import 'package:elec/elec.dart';
import 'package:elec_server/src/db/isoexpress/fuelmix_report.dart';
import 'package:elec_server/src/db/isoexpress/fwdres_auction_results.dart';
import 'package:elec_server/src/db/isoexpress/scc_report.dart';
import 'package:elec_server/src/db/nyiso/btm_solar_actual_mw.dart';
import 'package:elec_server/src/db/nyiso/btm_solar_forecast_mw.dart';
import 'package:elec_server/src/db/nyiso/masked_ids.dart';
import 'package:elec_server/src/db/nyiso/rt_zonal_load_hourly.dart';
import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';
import 'package:elec_server/src/db/utilities/retail_offers/retail_supply_offer.dart';
import 'package:elec_server/src/utils/convert_xls_to_xlsx.dart';
import 'package:http/http.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/api/isoexpress/api_isone_regulation_requirement.dart';
import 'package:elec_server/client/ftr_clearing_prices.dart';
import 'package:elec_server/client/weather/noaa_daily_summary.dart';
import 'package:elec_server/src/db/archive.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:elec_server/src/db/isoexpress/da_congestion_compact.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';
import 'package:elec_server/src/db/isoexpress/monthly_asset_ncpc.dart';
import 'package:elec_server/src/db/isoexpress/regulation_requirement.dart';
import 'package:elec_server/src/db/isoexpress/wholesale_load_cost_report.dart';
import 'package:elec_server/src/db/isoexpress/zonal_demand.dart';
import 'package:elec_server/src/db/isone/masked_ids.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/src/db/marks/curves/curve_id/curve_id_isone.dart';
import 'package:elec_server/src/db/mis/sd_rtload.dart';
import 'package:elec_server/src/db/nyiso/binding_constraints.dart';
import 'package:elec_server/src/db/nyiso/da_congestion_compact.dart';
import 'package:elec_server/src/db/nyiso/da_energy_offer.dart';
import 'package:elec_server/src/db/nyiso/da_lmp_hourly.dart';
import 'package:elec_server/src/db/nyiso/nyiso_ptid.dart' as nyiso_ptid;
import 'package:elec_server/src/db/nyiso/tcc_clearing_prices.dart'
    as nyiso_tcc_cp;
import 'package:elec_server/src/db/pjm/pjm_ptid.dart' as pjm_ptid;

import 'package:elec_server/src/db/weather/noaa_daily_summary.dart';
import 'package:path/path.dart' as path;
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/marks/curves/forward_marks.dart';
import 'package:elec_server/src/db/other/isone_ptids.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import '../test/db/marks/marks_special_days.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:path/path.dart';

/// ============================================================================
/// Create the MongoDb from scratch to pass all tests.  This script is useful
/// if you update the MongoDb installation and all the data is erased.
///

var env = Platform.environment;

Future<void> insertBtmSolarActualMwNyiso() async {
  var archive = NyisoBtmSolarActualArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();
  var months = Month.utc(2020, 11).upTo(Month.utc(2022, 9));
  for (var month in months) {
    await archive.downloadMonth(month);
    for (var date in month.days()) {
      var file = archive.getCsvFile(date);
      var data = archive.processFile(file);
      // print(data.length);
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> insertBtmSolarForecastMwNyiso() async {
  var archive = NyisoBtmSolarForecastArchive();
  // await archive.setupDb();
  await archive.dbConfig.db.open();
  var months = Month.utc(2020, 11).upTo(Month.utc(2022, 9));
  for (var month in months) {
    await archive.downloadMonth(month);
    for (var date in month.days()) {
      var file = archive.getCsvFile(date);
      var data = archive.processFile(file);
      // print(data.length);
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}


Future<void> insertCompetitiveOffers() async {
  var archive = RetailSuppliersOffersArchive();
  // await archive.setupDb();
  // await archive.saveCurrentRatesToFile();
  await archive.dbConfig.db.open();

  var date = Date.utc(2022, 12, 4);
  var file = File(join(archive.dir, '${date.toString()}_ct.json'));
  var data = archive.processFile(file);
  await archive.insertData(data);
  await archive.dbConfig.db.close();
}



Future<void> insertDaBindingConstraintsIsone() async {
  var archive = DaBindingConstraintsReportArchive();
  // var days = [
  //   Date.utc(2015, 2, 17), // empty file
  //   ...Term.parse('Jan17', UTC).days(),
  //   Date.utc(2017, 12, 31), // plenty of constraints
  //   Date.utc(2018, 7, 10), // has duplicates
  // ];
  var days = Term.parse('12Jan22-6Mar22', UTC).days();
  await insertDays(archive, days);
}

Future<void> insertDaBindingConstraintsNyiso() async {
  var archive = NyisoDaBindingConstraintsReportArchive();
  // await archive.setupDb();
  await archive.dbConfig.db.open();
  var months = Month.utc(2021, 3).upTo(Month.utc(2022, 2));
  for (var month in months) {
    // http://mis.nyiso.com/public/csv/DAMLimitingConstraints/20210201DAMLimitingConstraints.csv.zip
    await archive.downloadMonth(month);
    for (var date in month.days()) {
      var file = archive.getCsvFile(date);
      var data = archive.processFile(file);
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> insertDaCongestionCompactNyiso() async {
  /// get the list of ptids to ingest
  var client = FtrClearingPrices(Client(), iso: Iso.newYork);
  var cp = await client.getClearingPricesForAuction('X21-6M-R5Autumn21');

  var archive = NyisoDaCongestionCompactArchive()
    ..ptids = cp.map((e) => e['ptid'] as int).toSet();
  // await archive.setupDb();
  await archive.dbConfig.db.open();
  var months = Month.utc(2019, 2).upTo(Month.utc(2022, 2));
  for (var month in months) {
    for (var date in month.days()) {
      var data = archive.processDay(date);
      await archive.insertData([data]);
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> insertDaDemandBids() async {
  var archive = DaDemandBidArchive();

  // var days = [
  //   // Date.utc(2017, 1, 1),
  //   Date.utc(2017, 1, 2),
  //   Date.utc(2017, 1, 3),
  //   Date.utc(2017, 1, 4),
  //   Date.utc(2017, 1, 5),
  //   //   Date.utc(2017, 7, 1),
  //   //   Date.utc(2017, 7, 2),
  //   //   Date.utc(2017, 7, 3),
  //   //   Date.utc(2017, 7, 4),
  //   //   Date.utc(2017, 7, 5),
  //   //   Date.utc(2019, 2, 28),
  //   // Date.utc(2020, 9, 1),
  //   //   Date.utc(2020, 10, 1),
  // ];
  var days = Term.parse('Mar22', UTC).days();
  // await insertDays(archive, days, download: false);
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();

  // await archive.setupDb();
}

Future<void> insertDays(DailyIsoExpressReport archive, List<Date> days,
    {bool download = true}) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    if (download) {
      await archive.downloadDay(day);
    }
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> insertDaEnergyOffers({List<Date>? days}) async {
  /// What I need to pass the tests
  days ??= Term.parse('Jan17-Dec17', UTC).days();

  var archive = DaEnergyOfferArchive();
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> insertDaEnergyOffersNyiso() async {
  var archive = NyisoDaEnergyOfferArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();
  var months = Month.utc(2020, 2).upTo(Month.utc(2020, 3));
  for (var month in months) {
    await archive.downloadMonth(month);
    var file = archive.getCsvFile(month.startDate);
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> insertDaLmpHourlyNyiso() async {
  var archive = NyisoDaLmpHourlyArchive();
  // await archive.setupDb();
  await archive.dbConfig.db.open();
  var months = Month.utc(2022, 2).upTo(Month.utc(2022, 2));
  for (var month in months) {
    archive.nodeType = NodeType.zone;
    await archive.downloadMonth(month);
    archive.nodeType = NodeType.gen;
    await archive.downloadMonth(month);
    for (var date in month.days()) {
      var data = archive.processDay(date); // both zone and gen nodes
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}

void insertForwardMarks() async {
  var archive = ForwardMarksArchive();
  await archive.db.open();
  await archive.dbConfig.coll.remove(<String, dynamic>{});
  await archive.insertData(hourlyShape20191231());
  await archive.insertData(marks20200529());
  await archive.insertData(marks20200706());
  await archive.insertData(nodalMarks20200706());
  await archive.insertData(volatilitySurface());
  await archive.setup();
  await archive.db.close();
}

Future<void> insertFuelMixIsone(List<Date> days,
    {bool setup = false, bool externalDownload = true}) async {
  var archive = FuelMixReportArchive();
  if (setup) await archive.setupDb();

  await archive.dbConfig.db.open();
  for (var day in days) {
    if (externalDownload) await archive.downloadDay(day);
    var data = archive.processFile(archive.getFilename(day));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}


Future<void> insertFwdResAuctionResults() async {
  var archive = FwdResAuctionResultsArchive();
  await archive.dbConfig.db.open();
  var auctionNames = archive.urls.keys.toList();
  for (var auctionName in auctionNames) {
    var file = archive.getFilename(auctionName);
    await archive.downloadUrl(archive.getUrl(auctionName), file);
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> insertHourlyRtZonalLoadNyiso() async {
  var archive = NyisoHourlyRtZonalLoadReportArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();
  var months = Month.utc(2022, 1).upTo(Month.utc(2022, 9));
  for (var month in months) {
    await archive.downloadMonth(month);
    for (var date in month.days()) {
      var file = archive.getCsvFile(date);
      var data = archive.processFile(file);
      // print(data.length);
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> insertIsoExpress() async {
  var location = getLocation('America/New_York');
  // to pass tests
  // await insertDays(
  //     DaEnergyOfferArchive(), Term.parse('Jul17', location).days());

  // to calculate hourly shaping for Hub, need Jan19-Dec19
  var days = Term.parse('1Jun19-30Jun19', location).days();
  await insertDays(DaLmpHourlyArchive(), days);
  // await insertDays(DaCongestionCompactArchive(), days, download: false);

  // to calculate settlement prices for calculators, Jan20-Aug20
  // await insertDays(
  //     DaLmpHourlyArchive(), Term.parse('Jan20-Aug20', location).days());
}

Future<void> insertMaskedAssetIds() async {
  var archive = IsoNeMaskedIdsArchive();
  await archive.db.open();
  await archive.setup();
  var data = archive.readXlsx();
  await archive.insertMongo(data);
  await archive.db.close();
}

Future<void> insertMaskedAssetIdsNyiso() async {
  var archive = NyisoMaskedIdsArchive();
  await archive.db.open();
  await archive.setup();
  var data = archive.readXlsx();
  await archive.insertMongo(data);
  await archive.db.close();
}

void insertMisReports() async {
  var archive = SdRtloadArchive();
  await archive.dbConfig.db.open();
  await archive.dbConfig.coll.remove(<String, dynamic>{});
  var file = Directory('test/_assets')
      .listSync()
      .whereType<File>()
      .where((e) => basename(e.path).startsWith('sd_rtload_'))
      .first;
  var data = archive.processFile(file);
  await archive.insertTabData(data[0]!, tab: 0);
  await archive.dbConfig.db.close();
  await archive.setupDb();

  /// change the version and reinsert, so that you have two versions in the
  /// database
  for (var x in data[0]!) {
    x['version'] = TZDateTime.utc(2014, 3, 15);
  }
  await archive.dbConfig.db.open();
  await archive.insertTabData(data[0]!, tab: 0);
  await archive.dbConfig.db.close();
}

Future<void> insertMonthlyAssetNcpc({bool download = false}) async {
  // var months = [
  //   Month.utc(2019, 1),
  // ];
  var months = Term.parse('Jan19-Jun21', UTC)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt));
  var archive = MonthlyAssetNcpcArchive();
  await archive.dbConfig.db.open();
  for (var month in months) {
    print('Working on $month');
    if (download) {
      await archive.downloadMonth(month);
    }
    var data = archive.processFile(archive.getFilename(month));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> insertNoaaTemperatures({bool download = false}) async {
  var archive = NoaaDailySummaryArchive()
    ..dir = '${env['HOME'] ?? ''}/Downloads/Archive/Weather/Noaa/DailySummary/Raw/';
  await archive.dbConfig.db.open();

  /// what stations get inserted in the database
  var stationIds = NoaaDailySummary.airportCodeMap.values;

  for (var stationId in stationIds) {
    print('Working on stationId: $stationId');
    if (download) {
      var url = archive.getUrl(
          stationId, Date.utc(1970, 1, 1), Date.today(location: UTC));
      await archive.downloadUrl(url, archive.getFilename(stationId));
    }
    var data = archive.processFile(archive.getFilename(stationId));
    await archive.insertData(data);
  }

  await archive.dbConfig.db.close();
}

void insertPtidTable() async {
  var archive = PtidArchive();
  var baseUrl = 'https://www.iso-ne.com/static-assets/documents/';
  var urls = [
    '2019/02/2.6.20_pnode_table_2019_02_05.xlsx',
    '2020/06/pnode_table_2020_06_11.xlsx',
  ];
  if (!Directory(archive.dir).existsSync()) {
    Directory(archive.dir).createSync(recursive: true);
  }
  await archive.db.open();
  for (var url in urls) {
    await archive.downloadFile(baseUrl + url);
    var file = path.join(archive.dir, path.basename(url));
    await archive.insertMongo(File(file));
  }
  await archive.db.close();
}

Future<void> insertPtidTableNyiso() async {
  var archive = nyiso_ptid.PtidArchive();
  await archive.setupDb();

  await archive.downloadData();
  var data = archive.processData(Date.today(location: UTC));
  //print(data);

  await archive.db.open();
  await archive.insertData(data);
  await archive.db.close();
}

Future<void> insertPtidTablePjm() async {
  var archive = pjm_ptid.PtidArchive();
  await archive.setupDb();
  
  var data = archive.processData(Date.utc(2022, 3, 25));
  await archive.db.open();
  await archive.insertData(data);
  await archive.db.close();
}

Future<void> insertRegulationRequirement() async {
  var archive = RegulationRequirementArchive();
  await archive.setupDb();
  await archive.downloadFile();

  var data = archive.readAllData();
  await archive.db!.open();
  await archive.insertData(data);
  await archive.db!.close();
}

Future<void> insertSccReportIsone() async {
  var archive = SccReportArchive();
  // await archive.setupDb();

  var months = Month.utc(2018, 1).upTo(Month.utc(2018, 1));
  for (var month in months) {
    var url = archive.makeUrl(month);
    // await archive.downloadFile(url);
    var fileIn = File(join(archive.dir, basename(url)));
    await convertXlsToXlsx(fileIn);
  }


  // await archive.db.open();
  // var files = Directory(archive.dir).listSync().whereType<File>().where((e) => e.path.endsWith('.xlsx'));
  // for (var file in files) {
  //   print('Working on file ${file.path}');
  //   // var data = archive.readXlsx(file);
  //   // await archive.insertData(data);
  // }
  // await archive.db.close();
}


Future<void> insertTccClearedPricesNyiso() async {
  var config = ComponentConfig(
      host: 'localhost:27017',
      dbName: 'nyiso',
      collectionName: 'tcc_clearing_prices');
  var dir =
      '${env['HOME']!}/Downloads/Archive/Nyiso/TCC/ClearingPrices/ToProcess/';
  var archive = nyiso_tcc_cp.NyisoTccClearingPrices(config: config)..dir = dir;
  // await archive.setupDb();

  await archive.db.open();
  var files = Directory(archive.dir).listSync().whereType<File>();
  // var files = Directory(archive.dir).listSync().whereType<File>();
  for (var file in files) {
    print('Working on file ${file.path}');
    var data = archive.processFile(file);
    await archive.insertData(data);
    // move the files from the ToProcess folder to Raw
    var newPath = '${env['HOME']!}/Downloads/Archive/Nyiso/TCC/ClearingPrices/Raw/${path.basename(file.path)}';
    file.copySync(newPath);
    file.deleteSync();
  }

  await archive.db.close();
}

Future<void> insertWholesaleLoadReports() async {
  /// minimal setup to pass the tests
  var archive = WholesaleLoadCostReportArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();
  // await archive.dbConfig.coll.remove(<String, dynamic>{});
  var file = archive.getFilename(Month.utc(2019, 1), 4004);
  if (!file.existsSync()) {
    await archive.downloadFile(Month.utc(2019, 1), 4004);
  }
  var data = archive.processFile(file);
  await archive.insertData(data);
  await archive.dbConfig.db.close();
}

Future<void> insertZonalDemand() async {
  var archive = ZonalDemandArchive();
  // await ZonalDemandArchive().setupDb();

  var years = [
    2011,
    2012,
    2013,
    2014,
    2015,
    2016,
    2017,
    2018,
    2019,
    2020,
    2021,
    2022,
  ];
  // for (var year in years) {
  //   // download the files and convert to xlsx before 2017
  //   await archive.downloadYear(year);
  // }

  await archive.dbConfig.db.open();
  for (var year in years) {
    print('Year: $year');
    var file = archive.getFilename(year);
    var data = archive.processFile(file);
    // data.take(5).forEach(print);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}


Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  // await insertNoaaTemperatures(download: true);

  /// ------------- Isone -----------------
  // await insertDaBindingConstraintsIsone();
  
//  await insertForwardMarks();
//   await insertFwdResAuctionResults();
//   await insertIsoExpress();

  // var days = Date.utc(2020, 1, 1).upTo(Date.utc(2020, 1, 31));
  // await insertFuelMixIsone(days, setup: true, externalDownload: false);
  // await insertDaDemandBids();

  // await insertMaskedAssetIds();

  // insertRegulationRequirement();

  // insertMisReports();
  // await insertMonthlyAssetNcpc(download: false);

  //  await insertPtidTable();
  // await insertSccReportIsone();
  // await insertWholesaleLoadReports();
  // await insertZonalDemand();

  /// ----------- Nyiso -----------
  // await insertBtmSolarActualMwNyiso();
  // await insertBtmSolarForecastMwNyiso();
  // await insertDaBindingConstraintsNyiso();
  // await insertDaCongestionCompactNyiso();
  // await insertDaEnergyOffersNyiso();
  // await insertDaLmpHourlyNyiso();
  // await insertHourlyRtZonalLoadNyiso();
  // await insertMaskedAssetIdsNyiso();
  // await insertPtidTableNyiso();
  // await insertTccClearedPricesNyiso();


  /// ----------- PJM --------------
  // await insertPtidTablePjm();

  
  /// ----------- Utility data ----------
  await insertCompetitiveOffers();
  
}
