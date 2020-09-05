library test.db.isoexpress.monthly_wholesale_load_cost_test;

import 'dart:convert';

import 'package:elec_server/api/isoexpress/api_wholesale_load_cost.dart';
import 'package:elec_server/src/db/isoexpress/wholesale_load_cost_report.dart';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';


void tests() async {
  var archive = WholesaleLoadCostReportArchive();
  var api = WholesaleLoadCost(archive.dbConfig.db);
  group('Wholesale load cost report archive:', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read file Jan19, CT', () async {
      var file = archive.getFilename(Month(2019, 1), 4004);
      var xs = archive.processFile(file);
      expect(xs.length, 31);
      expect(xs.first.keys.toSet(), {'date',
        'ptid', 'rtLoad'});
      expect(xs.first['rtLoad'] is List, true);
    });
  });
  group('Wholesale load cost report API:', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('get rt load Jan19, CT', () async {
      var res = await api.apiGetZonalRtLoad(4004, '20190101', '20190131');
      var data = json.decode(res.result);
      expect(data.length, 31);
      expect(data.first.keys.toSet(), {'date', 'rtLoad'});
      expect(data.first['rtLoad'] is List, true);
    });
  });
}

void insertMonths({List<Month> months}) async {
  final location = getLocation('America/New_York');
  months ??= Term.parse('Jan19-Dec19', location)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt));

  var archive = WholesaleLoadCostReportArchive();
  await archive.dbConfig.db.open();
  var ptids = List.generate(8, (index) => 4001 + index);
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
 // await WholesaleLoadCostReportArchive().setupDb();

  // await insertMonths();
  await tests();

}