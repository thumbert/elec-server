library lib.src.db.lib_update_dbs;

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'lib_prod_archives.dart' as prod;

Future<void> updateCmeEnergySettlements(List<Date> days, {bool setUp = false}) async {
  var archive = prod.getCmeEnergySettlementsArchive();
  if (setUp) await archive.setupDb();
  // await archive.downloadDataToFile();
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

