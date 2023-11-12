import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/rt_system_demand_hourly.dart';

/// prepare data by downloading a few reports
prepareData() async {
  var archive = RtSystemDemandReportArchive();
  var days = [Date.utc(2018, 1, 1), Date.utc(2018, 1, 31)];
  await archive.downloadDays(days);
}

uploadDays() async {
  var location = getLocation('America/New_York');
  var archive = RtSystemDemandReportArchive();
//  var days = Interval(TZDateTime(location, 2016), TZDateTime(location, 2017))
//      .splitLeft((dt) => Date(dt.year, dt.month, dt.day, location: location));
  var days = [
    Date(2017, 9, 19, location: location),
    Date(2017, 12, 1, location: location),
  ];
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}

main() async {
  initializeTimeZones();

  //await RtSystemDemandReportArchive().setupDb();
  await uploadDays();

  //await prepareData();

//  await soloTest();
}
