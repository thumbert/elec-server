import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/db/isoexpress/ncpc_rapid_response_pricing_report.dart';


/// prepare data by downloading a few reports
prepareData() async {
  var archive = new NcpcRapidResponsePricingReportArchive();
  var days = [
    new Date(2017,3,1),
    new Date(2017,12,13)
  ];
  await archive.downloadDays(days);
}


ncpcRapidResponseTest() async {
  group('NCPC rapid response report', (){
    var archive = new NcpcRapidResponsePricingReportArchive();
    test('read files', () async {
      File file = archive.getFilename(new Date(2017,12,13));
      var report = new mis.MisReport(file);
      expect(await report.forDate(), new Date(2017,12,13));
      expect(await report.filename(), 'ncpc_rrp_20171213.csv');
      var data = report.readTabAsMap(tab: 0);
      expect(data.length, 1);
      var data2 = data.map((Map row) => archive.converter([row])).toList();
      expect(data2.first['RRP NCPC Charge'] is num, true);
    });
    test('insert one day', () async {
      await archive.dbConfig.db.open();
      await archive.insertDay(new Date(2017,3,1));
      await archive.dbConfig.db.close();
    });
    test('insert several days', () async {
      List days = new Interval(new DateTime(2017,3,2), new DateTime(2017,4))
          .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
      await archive.dbConfig.db.open();
      await for (var day in new Stream.fromIterable(days)) {
        archive.downloadDay(day);
        archive.insertDay(day);
      }
      archive.dbConfig.db.close();
    });

  });
}

main() async {
  await new NcpcRapidResponsePricingReportArchive().setupDb();

//  await prepareData();
  await ncpcRapidResponseTest();
}