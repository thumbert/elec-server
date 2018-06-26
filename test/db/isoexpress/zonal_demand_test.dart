
import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/db/isoexpress/zonal_demand.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


/// prepare data by downloading a few reports
prepareData(archive) async {
  File file = archive.getFilename(2016);
  List data = archive.processFile(file);
  data.take(5).forEach(print);
  return data;
}



main() async {
  await initializeTimeZone(getLocationTzdb());

  await new ZonalDemandArchive().setupDb();

  var archive = new ZonalDemandArchive();

  List years = [2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018];
  for (int year in years) {
    File file = archive.getFilename(year);
    List data = archive.processFile(file);
    data.take(5).forEach(print);
    await archive.dbConfig.db.open();
    await archive.insertData(data);
    await archive.dbConfig.db.close();
  }

}