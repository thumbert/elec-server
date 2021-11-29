
import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/db/isoexpress/da_cleared_demand_hourly.dart';
import 'package:elec_server/src/db/isoexpress/rt_system_demand_hourly.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

Location location = getLocation('America/New_York');

/// prepare data by downloading a few reports
prepareData() async {
  var archive = DaClearedDemandReportArchive();
  var days = [
    Date.utc(2015,2,17),    // empty file
    Date.utc(2017,12,13)    // plenty of constraints
  ];
  await archive.downloadDays(days);
}


DaClearedDemandTest() async {
  group('DA Cleared Demand report', (){
    test('read da cleared demand files', () async {
      var archive = DaClearedDemandReportArchive();
      File file = archive.getFilename(Date.utc(2017,1,1));
      var data = archive.processFile(file);
      expect(data.length, 1);
      expect(data.first['Day-Ahead Cleared Demand'].first, 11167.0);
    });
  });
}

uploadDaysDa() async {
  var archive = DaClearedDemandReportArchive();
  List days =
  Interval(TZDateTime(location, 2017, 1, 1),
      TZDateTime(location, 2018, 1, 1))
      .splitLeft((dt) => Date.utc(dt.year, dt.month, dt.day));
  await archive.dbConfig.db.open();
  await for (var day in Stream.fromIterable(days)) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}


uploadDaysRt() async {
  var archive = RtSystemDemandReportArchive();
  List days =
  Interval(TZDateTime(location, 2017, 1, 5),
      TZDateTime(location, 2017, 12, 20))
      .splitLeft((dt) => Date.utc(dt.year, dt.month, dt.day));
  await archive.dbConfig.db.open();
  await for (var day in Stream.fromIterable(days)) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}


main() async {
  await initializeTimeZone(getLocationTzdb());

  //await new DaClearedDemandReportArchive().setupDb();
  await DaClearedDemandTest();

  await uploadDaysDa();

  //await uploadDaysRt();



//  await prepareData();
//  await DaBindingConstraintsTest();

//  await soloTest();

}