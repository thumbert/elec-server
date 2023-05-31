library test.db.cme.cme_energy_settlements_test;

import 'package:date/date.dart';
import 'package:elec_server/api/cme/api_cme.dart';
import 'package:elec_server/src/db/cme/cme_energy_settlements.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:logging/logging.dart';

Future<void> tests() async {
  group('CME energy settlements db test:', () {
    var archive = CmeSettlementsEnergyArchive();
    test('get report date', () {
      var row0 = '        FINAL POST-CLEARING PRICES AS OF 04/28/2023 10:32 PM (CDT)';
      var date = archive.getReportDate(row0);
      expect(date, Date.utc(2023, 4, 28));
    });

    // test('download latest settlement file', () async {
    //   var res = await archive.downloadDataToFile();
    //   expect(res, 0);
    // });

    test('read file from 2023-04-28', () {
      var data = archive.processFile(archive.getFilename(Date.utc(2023, 4, 28)));
      expect(data.length > 1, true);
      var ttf = data.firstWhere((e) => e['curveId'] == 'NG_TTF_USD_CME');
      expect(ttf.keys.toSet(), {'fromDate', 'curveId', 'terms', 'values'});
      expect(ttf['terms'].first, '2023-05');
      expect(ttf['values'].first, 12.472);
      expect(ttf['terms'].last, '2026-12');
      expect(ttf['values'].last, 12.464);

      //
      var wti = data.firstWhere((e) => e['curveId'] == 'OIL_WTI_CME');
      expect(wti['terms'].first, '2023-06');
      expect(wti['values'].first, 76.78);
      expect(wti['terms'].last, '2034-02');
      expect(wti['values'].last, 52.38);
    });

  });

  group('CME energy settlements API test:', () {
    var api = ApiCmeMarks(DbProd.cme);
    setUp(() async {await DbProd.cme.open();});
    tearDown(() async {await DbProd.cme.close();});
    test('get all curveIds', () async {
      var curveIds = await api.allCurveIds('2023-04-28');
      expect(curveIds.length > 1, true);
      expect(curveIds.contains('NG_TTF_USD_CME'), true);
    });
    test('get the price for one curveIds as of a given date', () async {
      var x = await api.getPrice('NG_TTF_USD_CME', '2023-04-28');
      expect(x.keys.toSet(), {'terms', 'values'});
    });
  });

  group('CME energy settlements client test:', () {

  });
}


Future<void> main() async {
  initializeTimeZones();
  DbProd();
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  await tests();
}