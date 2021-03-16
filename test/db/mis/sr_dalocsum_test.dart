library test.mis.sr_dalocsum_test;

import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/api/mis/api_sr_dalocsum.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/mis/sr_dalocsum.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void tests() async {
  var dir = Directory('test/_assets');
  var file = dir
      .listSync()
      .where((e) => basename(e.path).startsWith('sr_dalocsum_'))
      .first;
  var archive = SrDaLocSumArchive();
  // await archive.setupDb();

  group('MIS report sr_dalocsum tests:', () {
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read and insert report', () async {
      var data = archive.processFile(file);
      expect(data.length, 2);
      // await archive.insertTabData(data[0], tab: 0);
      // await archive.insertTabData(data[1], tab: 1);
    });
  });

  group('MIS report sr_dalocsum api tests:', () {
    var db = DbProd.mis;
    var api = SrDaLocSum(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get daily da energy settlement, all locations', () async {
      var data = await api.dailyDaSettlementForAccount(
          '000000003', '2013-06-03', '2013-06-03', 0);
      expect(data.length, 20);
    });
    test('get daily da energy settlement, some locations', () async {
      var data = await api.dailyDaSettlementForAccountLocations(
          '000000003', '2013-06-03', '2013-06-03', '401,402', 0);
      expect(data.length, 2);
    });
    test('get daily da energy for subaccount, all locations', () async {
      var data = await api.dailyDaSettlementForSubaccount(
          '000000003', '9001', '2013-06-03', '2013-06-03', 0);
      expect(data.length, 20);
    });
    test('get daily da energy for subaccount, some locations', () async {
      var data = await api.dailyDaSettlementForSubaccountLocations(
          '000000003', '9001', '2013-06-03', '2013-06-03', '401,402', 0);
      expect(data.length, 2);
    });
  });
}

void insertMonths(List<Month> months) async {}

void main() async {
  await initializeTimeZones();
  DbProd();
  await tests();
}
