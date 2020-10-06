library test.mis.tr_sch3p2_test;

import 'dart:convert';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec_server/api/mis/api_tr_sch3p2.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/mis/tr_sch2tp.dart';
import 'package:elec_server/api/mis/api_tr_sch2tp.dart';
import 'package:elec_server/src/db/mis/tr_sch3p2.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void tests() async {
  var dir = Directory('test/_assets');
  var file = dir
      .listSync()
      .where((e) => basename(e.path).startsWith('tr_sch3p2_'))
      .first;
  var archive = TrSch3p2Archive();
  //await archive.setupDb();

  group('MIS report tr_sch3p2 tests:', () {
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read report', () async {
      var data = archive.processFile(file);
      expect(data.length, 2);
      // await archive.insertTabData(data[0]);
      // await archive.insertTabData(data[1]);
    });
  });

  group('MIS report tr_sch3p2 api tests:', () {
    var db = DbProd.mis;
    var api = TrSch3p2(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get summary for account', () async {
      var aux = await api.dataForAccount('000000001', '2006-01', '2006-01');
      var data = json.decode(aux.result) as List;
      expect(data.length, 2);
      expect(data.first['Charges'], 27528);
    });
    test('get summary for subaccount', () async {
      var aux = await api.dataForSubaccount(
          '000000001', 'Default', '2006-01', '2006-01');
      var data = json.decode(aux.result) as List;
      expect(data.length, 2);
      expect(data.first['Charges'], 27528);
    });
  });
}

void insertMonths(List<Month> months) async {}

void main() async {
  await initializeTimeZones();
  DbProd();
  await tests();
}
