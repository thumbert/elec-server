import 'dart:io';
import 'package:elec_server/api/mis/api_sr_rtlocsum.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/src/db/mis/sr_rtlocsum.dart';

void tests() async {
  var dir = Directory(
      '${Platform.environment['HOME']!}/Downloads/Archive/Mis/all_samples');
  var file = dir
      .listSync()
      .where((e) => basename(e.path).startsWith('sr_rtlocsum_'))
      .first;
  var archive = SrRtLocSumArchive();

  setUp(() async {
    await archive.dbConfig.db.open();
    //await archive.setupDb();
  });
  tearDown(() async {
    await archive.dbConfig.db.close();
  });

  group('MIS report sr_rtlocsum', () {
    test('read report', () async {
      var data = archive.processFile(file as File);
      expect(data.length, 2);
      // await archive.insertTabData(data[0], tab: 0);
      // await archive.insertTabData(data[1], tab: 1);
    });
  });

  group('MIS report sr_rtlocsum api tests:', () {
    var db = DbProd.mis;
    var api = SrRtLocSum(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get daily rt energy settlement, all locations', () async {
      var data = await api.dailyRtSettlementForAccount(
          '000000001', '2015-06-01', '2015-06-01', 0);
      expect(data.length, 17);
    });
    test('get daily rt energy settlement, some locations', () async {
      var data = await api.dailyRtSettlementForAccountLocations(
          '000000001', '2015-06-01', '2015-06-01', '401,402', 0);
      expect(data.length, 2);
    });
    test('get daily rt energy for subaccount, all locations', () async {
      var data = await api.dailyRtSettlementForSubaccount(
          '000000001', '9001', '2015-06-01', '2015-06-01', 0);
      expect(data.length, 17);
    });
    test('get daily rt energy for subaccount, some locations', () async {
      var data = await api.dailyRtSettlementForSubaccountLocations(
          '000000001', '9001', '2015-06-01', '2015-06-01', '401,402', 0);
      expect(data.length, 2);
    });
  });
}

void main() async {
  initializeTimeZones();
  DbProd();
  tests();
}
