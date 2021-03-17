library test.mis.sr_rtlocsum_test;

import 'dart:io';
import 'package:elec_server/api/mis/api_sd_arrawdsum.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/mis/sd_arrawdsum.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/mis/sr_rtlocsum.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

void tests() async {
  var db = DbProd.mis;
  var rootUrl = dotenv.env['SHELF_ROOT_URL'];
  var archive = SdArrAwdSumArchive();
  var api = SdArrAwdSum(db);

  group('MIS report SD_ARRAWDSUM db tests:', () {
    var dir = Directory('test/_assets');
    var file = dir
        .listSync()
        .where((e) => basename(e.path).startsWith('sd_arrawdsum_'))
        .first;
    setUp(() async {
      await archive.dbConfig.db.open();
      //await archive.setupDb();
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
  group('MIS SD_ARRAWDSUM api tests:', () {
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get monthly arr dollars for one month', () async {
      var data = await api.arrDollars('000000001', '2012-06', '2012-06', 0);
      expect(data.length, 4);
      var x = data
          .where((e) => e['month'] == '2012-06' && e['Location ID'] == 601)
          .first;
      expect((x['Peak Hour Load'] as num).toStringAsFixed(2), '-95.31');
    });
    test('get monthly arr dollars for subaccount for one month', () async {
      var data = await api.arrDollarsForSubaccount(
          '000000001', '9001', '2012-06', '2012-06', 0);
      expect(data.length, 4);
      var x = data
          .where((e) => e['month'] == '2012-06' && e['Location ID'] == 601)
          .first;
      expect((x['Peak Hour Load'] as num).toStringAsFixed(2), '-95.31');
    });
  });
}

void main() async {
  initializeTimeZones();
  DbProd();
  dotenv.load('.env/prod.env');
  tests();
}
