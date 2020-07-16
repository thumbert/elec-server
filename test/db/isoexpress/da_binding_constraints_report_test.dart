
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
    Date(2015,2,17),    // empty file
    Date(2017,12,13)    // plenty of constraints
  ];
  await archive.downloadDays(days);
}


DaBindingConstraintsTest() async {
  group('DA binding constraints report', () {
    var archive = new DaBindingConstraintsReportArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read binding constraints files', () async {
      var file = archive.getFilename(Date(2017,12,13));
      var report = new mis.MisReport(file);
      //expect(await report.forDate(), new Date(2017,12,13));
      expect(await report.filename(), 'da_binding_constraints_final_20171213.csv');
      var data = report.readTabAsMap(tab: 0);
      expect(data.length, 38);
      var data2 = data.map((Map row) => archive.converter([row])).toList();
      expect(data2.first['Marginal Value'] is num, true);
    });
    test('empty file for 2015-02-17', () async {
      var file = DaBindingConstraintsReportArchive().getFilename(Date(2015,2,17));
      var report = mis.MisReport(file);
      var res = report.readTabAsMap(tab: 0);
      expect(res, []);
    });

    test('DA Binding Constraints Report for 2018-07-10 has duplicates', () async {
      var file = DaBindingConstraintsReportArchive().getFilename(Date(2018,7,10));
      var report = mis.MisReport(file);
      var res = report.readTabAsMap(tab: 0);
      await archive.insertDay(Date(2018, 7, 10));
      expect(res.length, 20);
    });

  });
}

uploadDays() async {
  var location = getLocation('America/New_York');
  var archive = DaBindingConstraintsReportArchive();
  var days = Interval(TZDateTime(location, 2017, 1, 1),
      TZDateTime(location, 2018, 1, 1))
      .splitLeft((dt) => Date(dt.year, dt.month, dt.day, location: location));
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}


main() async {
  await initializeTimeZone();

  //await DaBindingConstraintsReportArchive().setupDb();

//  await prepareData();
//  await DaBindingConstraintsTest();

  await uploadDays();

}