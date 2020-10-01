library test.mis.tr_sch2tp_test;

import 'dart:convert';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/mis/tr_sch2tp.dart';
import 'package:elec_server/api/mis/api_tr_sch2tp.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';


void tests() async {
  var dir = Directory('test/_assets');
  var file = dir
      .listSync()
      .where((e) => basename(e.path).startsWith('tr_sch2tp_'))
      .first;
  var archive = TrSch2tpArchive();
  // await archive.setupDb();

  group('MIS report tr_sch2tp tests:', () {
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
  
  group('MIS report tr_sch2tp api tests:', () {
    var db = DbProd.mis;
    var api = TrSch2tp(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('read report', () async {
      var aux = await api.reportData('000000001', '2007-01', '2007-01');
      var data = json.decode(aux.result) as List;
      expect(data.length, 2);
    });
    test('get summary for account', () async {
      var aux = await api.summaryForAccount('000000001', '2007-01', '2007-01',
          0);
      var data = json.decode(aux.result) as List;
      expect(data.length, 1);
      expect(data.first['Total ISO Schedule 2 Charges'], 212981.35);
    });
    test('get summary for subaccount', () async {
      var aux = await api.summaryForSubaccount('000000001', 'Default',
          '2007-01', '2007-01', 0);
      var data = json.decode(aux.result) as List;
      expect(data.length, 1);
      expect(data.first['Total ISO Schedule 2 Charges'], 211379.22);
    });

  });
  
}

void insertMonths(List<Month> months) async {

}

void main() async {
  await initializeTimeZones();
  DbProd();
  await tests();
}
