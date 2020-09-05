library test.db.isoexpress.ncpc_rapid_response_report_test;

import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/db/isoexpress/ncpc_rapid_response_pricing_report.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';


void tests() async {
  var archive = NcpcRapidResponsePricingReportArchive();
  group('NCPC rapid response report', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read files', () async {
      var file = archive.getFilename(Date(2017,12,13));
      var xs = archive.processFile(file);
      expect(xs.length, 1);
      expect(xs.first.keys.toSet(), {'date',
        'RRP NCPC Charge', 'RRP Real-Time Load Obligation',
        'RRP NCPC Charge Rate'});
      expect(xs.first['RRP NCPC Charge'] is num, true);
    });
  });
}

void insertDays() async {
  var archive = NcpcRapidResponsePricingReportArchive();
  await archive.dbConfig.db.open();
  var days = Interval(TZDateTime.utc(2017,3,2), TZDateTime.utc(2017,4,1))
      .splitLeft((dt) => Date(dt.year, dt.month, dt.day));
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}


void main() async {
//  await NcpcRapidResponsePricingReportArchive().setupDb();

  await insertDays();
  //await tests();

}