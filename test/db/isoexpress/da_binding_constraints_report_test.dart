
import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


/// prepare data by downloading a few reports
prepareData() async {
  var archive = new DaBindingConstraintsReportArchive();
  var days = [
    new Date(2015,2,17),    // empty file
    new Date(2017,12,13)    // plenty of constraints
  ];
  await archive.downloadDays(days);
}


DaBindingConstraintsTest() async {
  group('DA binding constraints report', (){
    test('read binding constraints files', () async {
      var archive = new DaBindingConstraintsReportArchive();
      File file = archive.getFilename(new Date(2017,12,13));
      var report = new mis.MisReport(file);
      expect(await report.forDate(), new Date(2017,12,13));
      expect(await report.filename(), 'da_binding_constraints_final_20171213.csv');
      var data = report.readTabAsMap(tab: 0);
      expect(data.length, 38);
      var data2 = data.map((Map row) => archive.converter([row])).toList();
      expect(data2.first['Marginal Value'] is num, true);
    });

    test('DA Binding Constraints Report - empty', () async {
      File file = new DaBindingConstraintsReportArchive().getFilename(new Date(2015,2,17));
      var report = new mis.MisReport(file);
      var res = report.readTabAsMap(tab: 0);
      expect(res, []);
    });


  });
}

uploadDays() async {
  var archive = new DaBindingConstraintsReportArchive();
  List days =
  new Interval(new DateTime(2017, 1, 1), new DateTime(2017, 1, 5))
      .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
  await archive.dbConfig.db.open();
  await for (var day in new Stream.fromIterable(days)) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}


main() async {
  await initializeTimeZone(getLocationTzdb());

  //await new DaBindingConstraintsReportArchive().setupDb();

//  await prepareData();
//  await DaBindingConstraintsTest();

//  await soloTest();

}