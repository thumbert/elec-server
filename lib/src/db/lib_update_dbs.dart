library lib.src.db.lib_update_dbs;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:timezone/timezone.dart';
import 'lib_prod_archives.dart' as prod;


Future<void> updateCmeEnergySettlements(List<Date> days, {bool setUp = false}) async {
  var archive = prod.getCmeEnergySettlementsArchive();
  if (setUp) await archive.setupDb();
  await archive.dbConfig.db.open();
  for (var asOfDate in days) {
    var file = archive.getFilename(asOfDate);
    if (file.existsSync()) {
      var data = archive.processFile(file);
      await archive.insertData(data);
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

Future<void> updatePolygraphProjects({bool setUp = false}) async {
  var archive = prod.getPolygraphArchive();
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
