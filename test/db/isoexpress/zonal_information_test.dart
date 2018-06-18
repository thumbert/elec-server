
import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/db/isoexpress/zonal_information.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


/// prepare data by downloading a few reports
prepareData() async {
  var archive = new ZonalInformationArchive();
  File file = archive.getFilename(2018);
  List data = archive.processFile(file);
  data.take(5).forEach(print);

  await archive.dbConfig.db.open();
  await archive.insertData(data);
  await archive.dbConfig.db.close();

}



main() async {
  await initializeTimeZone(getLocationTzdb());

  //await new ZonalInformationArchive().setupDb();

  await prepareData();

//  await soloTest();

}