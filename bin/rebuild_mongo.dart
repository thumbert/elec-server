
import 'dart:io';
import 'package:elec_server/client/utilities/cmp/cmp.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:elec_server/src/db/utilities/maine/load_cmp.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/ftr_clearing_prices.dart';
import 'package:elec_server/client/weather/noaa_daily_summary.dart';
import 'package:elec_server/src/db/cme/cme_energy_settlements.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:elec_server/src/db/isoexpress/da_congestion_compact.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/isoexpress/fwdres_auction_results.dart';
import 'package:elec_server/src/db/isoexpress/monthly_asset_ncpc.dart';
import 'package:elec_server/src/db/isoexpress/regulation_requirement.dart';
import 'package:elec_server/src/db/isoexpress/rt_lmp_hourly.dart';
import 'package:elec_server/src/db/isoexpress/wholesale_load_cost_report.dart';
import 'package:elec_server/src/db/marks/curves/curve_id.dart';
import 'package:elec_server/src/db/mis/sd_rtload.dart';
import 'package:elec_server/src/db/mis/sr_dalocsum.dart';
import 'package:elec_server/src/db/mis/sr_rtlocsum.dart';
import 'package:elec_server/src/db/mis/tr_sch2tp.dart';
import 'package:elec_server/src/db/mis/tr_sch3p2.dart';
import 'package:elec_server/src/db/nyiso/binding_constraints.dart';
import 'package:elec_server/src/db/nyiso/da_congestion_compact.dart';
import 'package:elec_server/src/db/nyiso/da_energy_offer.dart';
import 'package:elec_server/src/db/nyiso/da_lmp_hourly.dart';
import 'package:elec_server/src/db/nyiso/nyiso_ptid.dart' as nyiso_ptid;
import 'package:elec_server/src/db/nyiso/rt_lmp_hourly.dart';
import 'package:elec_server/src/db/nyiso/tcc_clearing_prices.dart';
import 'package:elec_server/src/db/other/isone_ptids.dart' as isone_ptid;
import 'package:elec_server/src/db/pjm/pjm_ptid.dart' as pjm_ptid;
import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';
import 'package:elec_server/src/db/weather/noaa_daily_summary.dart';
import 'package:elec_server/src/db/marks/curves/curve_id/curve_id_ng.dart' as id_ng;
import 'package:elec_server/src/db/marks/curves/curve_id/curve_id_isone.dart' as id_isone;


Future<void> recreateCmeMarks() async {
  var archive = CmeSettlementsEnergyArchive();
  await archive.setupDb();
  var files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.zip'))
      .toList();
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateCmpLoadArchive({bool setUp = false}) async {
  var years = IntegerRange(2019, DateTime.now().year+1);
  var archive = getCmpLoadArchive();
  if (setUp) await archive.setupDb();
  await archive.dbConfig.db.open();
  for (var year in years) {
    for (var customerClass in CmpCustomerClass.values) {
      var file = archive.getFile(year: year, customerClass: customerClass,
          settlementType: 'final');
      if (file.existsSync()) {
        var data = archive.processFile(year: year, customerClass: customerClass,
            settlementType: 'final');
        print(data);
        await archive.insertData(data);
      }
    }
  }
  await archive.dbConfig.db.close();
}



Future<void> recreateDaBindingConstraintsIsone() async {
  var archive = DaBindingConstraintsReportArchive();
  await archive.setupDb();
  var files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.json'))
      .toList();
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateDaLmpHourlyIsone() async {
  var archive = DaLmpHourlyArchive();
  await archive.setupDb();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateRtLmpHourlyIsone() async {
  var archive = RtLmpHourlyArchive();
  await archive.setupDb();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateDaCongestionCompactIsone() async {
  var archive = DaCongestionCompactArchive();
  await archive.setupDb();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateDaDemandBid() async {
  var archive = DaDemandBidArchive();
  await archive.setupDb();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateDaEnergyOffersIsone() async {
  var archive = DaEnergyOfferArchive();
  await archive.setupDb();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateFwdResAuctionResults() async {
  var archive = FwdResAuctionResultsArchive();
  await archive.setupDb();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateMonthlyAssetNcpc() async {
  var archive = MonthlyAssetNcpcArchive();
  await archive.setupDb();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateDaBindingConstraintsNyiso() async {
  var archive = NyisoDaBindingConstraintsReportArchive();
  await archive.setupDb();
  var files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.zip'))
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var yyyymm = basename(file.path).substring(0, 6);
    var month = Month.parse(yyyymm, location: UTC);
    var xs = <Map<String, dynamic>>[];
    for (var date in month.days()) {
      var dailyFile = archive.getCsvFile(date);
      var data = archive.processFile(dailyFile);
      xs.addAll(data);
    }
    await archive.insertData(xs);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateDaCongestionCompactNyiso() async {
  var client = FtrClearingPrices(Client(), iso: Iso.newYork);
  var cp = await client.getClearingPricesForAuction('X21-6M-R5Autumn21');
  var ptids = cp.map((e) => e['ptid'] as int).toSet();
  if (ptids.isEmpty) {
    throw StateError('Need to ingest TCC clearing prices first!');
  }

  var archive = NyisoDaCongestionCompactArchive()..ptids = ptids;
  await archive.setupDb();
  var files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.zip'))
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var yyyymm = basename(file.path).substring(0, 6);
    var month = Month.parse(yyyymm, location: UTC);
    for (var date in month.days()) {
      var data = archive.processDay(date);
      await archive.insertData([data]);
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateDaLmpHourlyNyiso() async {
  var archive = NyisoDaLmpHourlyArchive();
  await archive.setupDb();
  var files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.zip'))
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var yyyymm = basename(file.path).substring(0, 6);
    var month = Month.parse(yyyymm, location: UTC);
    for (var date in month.days()) {
      var data = archive.processDay(date);
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateTccClearedPricesNyiso() async {
  var archive = NyisoTccClearingPrices();
  await archive.setupDb();
  await archive.db.open();
  var files = Directory(archive.dir).listSync().whereType<File>();
  for (var file in files) {
    print('Working on file ${file.path}');
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.db.close();
}

Future<void> recreateDaEnergyOffersNyiso() async {
  var archive = NyisoDaEnergyOfferArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();

  var files = Directory(archive.dir).listSync().whereType<File>();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}


Future<void> recreateIesoRtGenerationArchive() async {
  var archive = getIesoRtGenerationArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();

  var files = Directory(archive.dir).listSync().whereType<File>();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateIesoRtZonalDemandArchive() async {
  var archive = getIesoRtZonalDemandArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();

  var files = Directory(archive.dir).listSync().whereType<File>();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}


Future<void> recreateRtLmpHourlyNyiso() async {
  var archive = NyisoRtLmpHourlyArchive();
  await archive.dbConfig.db.open();
  var files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.zip'))
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  for (var file in files) {
    var yyyymm = basename(file.path).substring(0, 6);
    var month = Month.parse(yyyymm, location: UTC);
    for (var date in month.days()) {
      var data = archive.processDay(date); // both zone and gen nodes
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}

Future<void> recreatePtidTableIsone() async {
  var archive = isone_ptid.PtidArchive();
  await archive.setupDb();
  await archive.db.open();
  var files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.xlsx'))
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  for (var file in files) {
    await archive.insertMongo(file);
  }
  await archive.db.close();
}

Future<void> recreateRegulationRequirementIsone() async {
  var archive = RegulationRequirementArchive();
  await archive.setupDb();
  var data = archive.readAllData();
  await archive.db.open();
  await archive.insertData(data);
  await archive.db.close();
}

Future<void> recreateCompetitiveOffersIsone() async {
  var archive = RetailSuppliersOffersArchive();
  await archive.setupDb();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  await archive.dbConfig.db.open();
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> recreateMisTemplateArchive() async {
  {
    // var archive = SdArrAwdSumArchive();
    // var file = Directory('test/_assets')
    //     .listSync()
    //     .firstWhere((e) => basename(e.path).startsWith('sd_arrawdsum_'))
    // as File;
    // var data = archive.processFile(file);
    // await archive.dbConfig.db.open();
    // await archive.insertTabData(data[0]!);
    // await archive.insertTabData(data[1]!);
    // await archive.dbConfig.db.close();
  }
  //
  //
  {
    var archive = SdRtloadArchive();
    var file = Directory('test/_assets')
        .listSync()
        .firstWhere((e) => basename(e.path).startsWith('sd_rtload_')) as File;
    var data = archive.processFile(file);
    await archive.dbConfig.db.open();
    await archive.insertTabData(data[0]!, tab: 0);
    await archive.dbConfig.db.close();
  }
  //
  //
  {
    var archive = SrDaLocSumArchive();
    var file = Directory('test/_assets')
        .listSync()
        .firstWhere((e) => basename(e.path).startsWith('sr_dalocsum')) as File;
    var data = archive.processFile(file);
    await archive.dbConfig.db.open();
    await archive.insertTabData(data[0]!, tab: 0);
    await archive.insertTabData(data[1]!, tab: 1);
    await archive.dbConfig.db.close();
  }
  //
  //
  {
    var archive = SrRtLocSumArchive();
    var file = Directory('test/_assets')
        .listSync()
        .firstWhere((e) => basename(e.path).startsWith('sr_rtlocsum')) as File;
    var data = archive.processFile(file);
    await archive.dbConfig.db.open();
    await archive.insertTabData(data[0]!, tab: 0);
    await archive.insertTabData(data[1]!, tab: 1);
    await archive.dbConfig.db.close();
  }
  //
  //
  {
    var archive = TrSch2tpArchive();
    var file = Directory('test/_assets')
        .listSync()
        .firstWhere((e) => basename(e.path).startsWith('tr_sch2tp_')) as File;
    var data = archive.processFile(file);
    await archive.dbConfig.db.open();
    await archive.insertTabData(data[0]!);
    await archive.insertTabData(data[1]!);
    await archive.dbConfig.db.close();
  }
  //
  //
  {
    var archive = TrSch3p2Archive();
    var file = Directory('test/_assets')
        .listSync()
        .firstWhere((e) => basename(e.path).startsWith('tr_sch3p2_')) as File;
    var data = archive.processFile(file);
    await archive.dbConfig.db.open();
    await archive.insertTabData(data[0]!);
    await archive.insertTabData(data[1]!);
    await archive.dbConfig.db.close();
  }
}

Future<void> recreatePtidTableNyiso() async {
  var archive = nyiso_ptid.PtidArchive();
  await archive.setupDb();
  await archive.db.open();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  for (var file in files) {
    var yyyymmdd = basename(file.path).substring(10, 20);
    var date = Date.parse(yyyymmdd, location: UTC);
    var data = archive.processData(date);
    await archive.insertData(data);
  }

  await archive.db.close();
}

Future<void> recreatePtidTablePjm() async {
  var archive = pjm_ptid.PtidArchive();
  await archive.setupDb();
  await archive.db.open();
  var files = Directory(archive.dir).listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  for (var file in files) {
    var yyyymmdd = basename(file.path).substring(6, 16);
    var date = Date.parse(yyyymmdd, location: UTC);
    var data = archive.processData(date);
    await archive.insertData(data);
  }

  await archive.db.close();
}

Future<void> recreateNoaaTemperatures() async {
  var archive = NoaaDailySummaryArchive();
  await archive.dbConfig.db.open();

  var stationIds = NoaaDailySummary.airportCodeMap.values;
  for (var stationId in stationIds) {
    var data = archive.processFile(archive.getFilename(stationId));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}

Future<void> rebuildCurveIds() async {
  var archive = CurveIdArchive();
  await archive.db.open();
  await archive.dbConfig.coll.remove(<String, dynamic>{});
  await archive.insertData(id_isone.getCurves());
  await archive.insertData(id_ng.getCurves());
  await archive.setup();
  await archive.db.close();
}

Future<void> recreateWholesaleLoadCostReportIsone() async {
  var archive = WholesaleLoadCostReportArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();
  var files = Directory(archive.dir).listSync().whereType<File>()
      .where((e) => e.path.endsWith('.json'))
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  for (var file in files) {
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}



/// If you have a fresh MongoDB install, recreate the db from the
/// backup files in the archive folder.
///
/// The Archive folder needs to be already populated with the files of interest.
///
Future<void> main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  dotenv.load('.env/prod.env');

  /// NOTE:  the bin/server.dart needs to be running
  /// This creation order needs to be preserved!

  /// IESO
  // await recreateIesoRtGenerationArchive();
  // await recreateIesoRtZonalDemandArchive();

  /// ISONE
  // await recreateDaBindingConstraintsIsone();
  // await recreateDaLmpHourlyIsone();
  // await recreateRtLmpHourlyIsone();
  // await recreateDaCongestionCompactIsone();
  // await recreateDaDemandBid();
  // await recreateDaEnergyOffersIsone();
  // await recreateFwdResAuctionResults();
  // await insertMaskedAssetIdsIsone();
  // await recreatePtidTableIsone();
  // await recreateRegulationRequirementIsone();
  // await recreateCompetitiveOffersIsone();
  // await recreateMisTemplateArchive();
  // await recreateWholesaleLoadCostReportIsone();

  /// NYISO
  // await insertMaskedAssetIdsNyiso();
  // await recreateMonthlyAssetNcpc();
  // await recreateDaBindingConstraintsNyiso();
  // await recreateDaLmpHourlyNyiso();
  // await recreateTccClearedPricesNyiso();
  // await recreateDaCongestionCompactNyiso();
  // await recreateDaEnergyOffersNyiso();
  // await recreateRtLmpHourlyNyiso();
  // await recreatePtidTableNyiso();

  /// PJM
  // await recreatePtidTablePjm();

  /// Other
  // await recreateNoaaTemperatures();
  // await rebuildCurveIds();
  // await insertForwardMarks();
  // await recreateCmeMarks();
  // await updatePolygraphProjects(setUp: true);

  /// Utilities
  await recreateCmpLoadArchive(setUp: true);
}
