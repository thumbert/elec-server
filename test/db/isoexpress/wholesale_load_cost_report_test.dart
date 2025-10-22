import 'package:elec_server/api/isoexpress/api_wholesale_load_cost.dart';
import 'package:elec_server/src/db/isoexpress/wholesale_load_cost_report.dart';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

Future<void> tests() async {
  var archive = WholesaleLoadCostReportArchive();
  var api = WholesaleLoadCost(archive.dbConfig.db);
  group('Wholesale load cost report db tests: ', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read file Jan19, CT', () async {
      var file = archive.getFilename(Month.utc(2019, 1), 4004);
      var xs = archive.processFile(file);
      expect(xs.length, 31);
      expect(xs.first.keys.toSet(), {'date', 'ptid', 'rtLoad'});
      expect(xs.first['rtLoad'] is List, true);
      var rtLoad = xs.first['rtLoad'] as List;
      expect(rtLoad.first, 2713.617);
      expect(xs.first['date'], '2019-01-01');
    });
  });
  group('Wholesale load cost report API tests: ', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('get CT RT load for Jan19', () async {
      var data = await api.apiGetZonalRtLoad(4004, '20190101', '20190131');
      expect(data.length, 31);
      expect(data.first.keys.toSet(), {'date', 'rtLoad'});
      expect(data.first['rtLoad'] is List, true);
    });
  });
}

void insertMonths({List<Month>? months}) async {
  final location = getLocation('America/New_York');
  months ??= Term.parse('Jan16-Dec16', location)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt));

  var archive = WholesaleLoadCostReportArchive();
  await archive.dbConfig.db.open();
  var ptids = List.generate(8, (index) => 4000 + index);
  for (var month in months) {
    for (var ptid in ptids) {
      await archive.downloadFile(month, ptid);
      var data = archive.processFile(archive.getFilename(month, ptid));
      await archive.insertData(data);
    }
  }
  await archive.dbConfig.db.close();
}

void main() async {
  initializeTimeZones();
  // await WholesaleLoadCostReportArchive().setupDb();

  await tests();
}
