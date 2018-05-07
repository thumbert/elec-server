
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
  var days = [
    new Date(2018,1,1),
    new Date(2018,1,31)
  ];
  await archive.downloadDays(days);
}


//DaBindingConstraintsTest() async {
//  group('DA binding constraints report', (){
//    test('read binding constraints files', () async {
//      var archive = new RtSystemDemandReportArchive();
//      File file = archive.getFilename(new Date(2017,12,13));
//      var report = new mis.Report(file);
//      expect(await report.forDate(), new Date(2017,12,13));
//      expect(await report.filename(), 'da_binding_constraints_final_20171213.csv');
//      var data = report.readTabAsMap(tab: 0);
//      expect(data.length, 38);
//      var data2 = data.map((Map row) => archive.converter([row])).toList();
//      expect(data2.first['Marginal Value'] is num, true);
//    });
//  });
//}

uploadDays() async {
  var archive = new RtSystemDemandReportArchive();
  List days =
  new Interval(new DateTime(2014, 1, 1), new DateTime(2018, 4, 1))
      .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
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