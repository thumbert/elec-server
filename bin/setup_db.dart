import 'dart:io';

import 'package:elec_server/src/db/isoexpress/wholesale_load_cost_report.dart';
import 'package:path/path.dart' as path;
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/marks/curves/forward_marks.dart';
import 'package:elec_server/src/db/other/isone_ptids.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import '../test/db/marks/marks_special_days.dart';

/// Create the MongoDb from scratch to pass all tests.  This script is useful
/// if you update the MongoDb installation and all the data is erased.
///

void insertDays(archive, List<Date> days) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

void insertForwardMarks() async {
  var archive = ForwardMarksArchive();
  await archive.db.open();
  var data = marks20200529();
  await archive.insertData(data);
  await archive.db.close();
}

void insertIsoExpress() async {
  var location = getLocation('America/New_York');
  // to pass tests
//  await insertDays(DaEnergyOfferArchive(),
//      Term.parse('Jul17', location).days());

  // to calculate hourly shaping for Hub, need Jan19-Dec19
//  await insertDays(DaLmpHourlyArchive(),
//      Term.parse('Jan19-Dec19', location).days());
  // to calculate settlement prices for calculators, Jan20-Aug20
  await insertDays(
      DaLmpHourlyArchive(), Term.parse('Jan20-Aug20', location).days());

  await insertWholesaleLoadReports();
}

void insertWholesaleLoadReports() async {
  /// minimal setup to pass the tests
  var archive = WholesaleLoadCostReportArchive();
  await archive.dbConfig.db.open();
  await archive.dbConfig.coll.remove(<String, dynamic>{});
  var file = archive.getFilename(Month(2019, 1), 4004);
  if (!file.existsSync()) {
    await archive.downloadFile(Month(2019, 1), 4004);
  }
  var data = archive.processFile(file);
  await archive.insertData(data);
  await archive.dbConfig.db.close();
  await archive.setupDb();
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

void main() async {
  await initializeTimeZones();

//  await insertForwardMarks();
//  await insertIsoExpress();
//  await insertPtidTable();

  await insertWholesaleLoadReports();
}
