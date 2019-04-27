import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/db/isoexpress/rt_system_demand_hourly.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

/// prepare data by downloading a few reports
prepareData() async {
  var archive = new RtSystemDemandReportArchive();
  var days = [new Date(2018, 1, 1), new Date(2018, 1, 31)];
  await archive.downloadDays(days);
}

uploadDays() async {
  var location = getLocation('US/Eastern');
  var archive = RtSystemDemandReportArchive();
  var days = Interval(
          TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2018, 1, 1))
      .splitLeft((dt) => Date(dt.year, dt.month, dt.day, location: location));
  await archive.dbConfig.db.open();
  for (var day in days) {
    print(day);
    //await archive.downloadDay(day, override: false);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}

main() async {
  await initializeTimeZone(getLocationTzdb());

  //await new RtSystemDemandReportArchive().setupDb();
  await uploadDays();

  //await prepareData();

//  await soloTest();
}
