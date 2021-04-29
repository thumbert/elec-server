import 'dart:io';

import 'package:elec_server/api/isoexpress/api_isone_regulation_requirement.dart';
import 'package:elec_server/src/db/archive.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';
import 'package:elec_server/src/db/isoexpress/regulation_requirement.dart';
import 'package:elec_server/src/db/isoexpress/wholesale_load_cost_report.dart';
import 'package:elec_server/src/db/isoexpress/zonal_demand.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/src/db/marks/curves/curve_id/curve_id_isone.dart';
import 'package:elec_server/src/db/mis/sd_rtload.dart';
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

Future<void> insertDaBindingConstraints() async {
  var archive = DaBindingConstraintsReportArchive();
  var days = [
    Date(2015, 2, 17), // empty file
    Date(2017, 12, 31), // plenty of constraints
    Date(2018, 7, 10), // has duplicates
  ];
  for (var date in days) {
    await archive.downloadDay(date);
  }
}

Future<void> insertDaDemandBids() async {
  var archive = DaDemandBidArchive();

  var days = [Date(2020, 10, 1)];
  // var days = Month(2019, 2).days();
  await insertDays(archive, days);

  // await archive.setupDb();
}

Future<void> insertDays(DailyIsoExpressReport archive, List<Date> days) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> insertDaEnergyOffers({List<Date> days}) async {
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

void insertIsoExpress() async {
  var location = getLocation('America/New_York');
//  // to pass tests
//  await insertDays(DaEnergyOfferArchive(),
//      Term.parse('Jul17', location).days());

  // to calculate hourly shaping for Hub, need Jan19-Dec19
  await insertDays(
      DaLmpHourlyArchive(), Term.parse('Jan19-Dec19', location).days());
  // to calculate settlement prices for calculators, Jan20-Aug20
  await insertDays(
      DaLmpHourlyArchive(), Term.parse('Jan20-Aug20', location).days());
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
  await archive.insertTabData(data[0], tab: 0);
  await archive.dbConfig.db.close();
  await archive.setupDb();

  /// change the version and reinsert, so that you have two versions in the
  /// database
  for (var x in data[0]) {
    x['version'] = TZDateTime.utc(2014, 3, 15);
  }
  await archive.dbConfig.db.open();
  await archive.insertTabData(data[0], tab: 0);
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

void insertRegulationRequirement() async {
  var archive = RegulationRequirementArchive();
  await archive.setupDb();
  await archive.downloadFile();

  var data = archive.readAllData();
  await archive.db.open();
  await archive.insertData(data);
  await archive.db.close();
}

void insertWholesaleLoadReports() async {
  /// minimal setup to pass the tests
  var archive = WholesaleLoadCostReportArchive();
  await archive.setupDb();
  await archive.dbConfig.db.open();
  // await archive.dbConfig.coll.remove(<String, dynamic>{});
  var file = archive.getFilename(Month(2019, 1), 4004);
  if (!file.existsSync()) {
    await archive.downloadFile(Month(2019, 1), 4004);
  }
  var data = archive.processFile(file);
  await archive.insertData(data);
  await archive.dbConfig.db.close();
}

Future<void> insertZonalDemand() async {
  var archive = ZonalDemandArchive();
  await ZonalDemandArchive().setupDb();

  var years = [2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021];
  for (var year in years) {
    // download the files and convert to xlsx
  }

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

/// Try to redo them all
void redoAll() async {
  // TODO
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  // await insertDaBindingConstraints();

//  await insertForwardMarks();
//   await insertIsoExpress();

  // await insertDaDemandBids();

  // insertRegulationRequirement();

  // insertMisReports();

//  await insertPtidTable();

 await insertWholesaleLoadReports();

  // await insertZonalDemand();

}
