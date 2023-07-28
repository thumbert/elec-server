library test.db.cme.cme_energy_settlements_test;

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:date/date.dart';
import 'package:elec_server/api/cme/api_cme.dart';
import 'package:elec_server/client/marks/forward_marks2.dart';
import 'package:elec_server/src/db/cme/cme_energy_settlements.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:logging/logging.dart';

Future<void> tests(String rootUrl) async {
  group('CME energy settlements db test:', () {
    var archive = CmeSettlementsEnergyArchive();
    test('get report date', () {
      var row0 = '        FINAL POST-CLEARING PRICES AS OF 04/28/2023 10:32 PM (CDT)';
      var date = archive.getReportDate(row0);
      expect(date, Date.utc(2023, 4, 28));
    });

    test('read file from 2023-04-28', () {
      var file = archive.getFilename(Date.utc(2023, 4, 28));
      var data = archive.processFile(file);
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
    var client = ForwardMarks2(rootUrl: rootUrl);
    test('get all curve ids', () async {
      var ids = await client.getCurveNames(asOfDate: Date.utc(2023, 7, 6),
          markType: MarkType.price);
      expect(ids.length > 3, true);
    });
    test('get price for one as of date', () async {
      var ts = await client.getPriceCurveForAsOfDate(asOfDate: Date.utc(2023, 7, 6),
          curveName: 'NG_HENRY_HUB_CME');
      expect(ts.length, 149);
      expect(ts.first, IntervalTuple<num>(Month.utc(2023, 8), 2.609));
    });
  });
}


Future<void> main() async {
  initializeTimeZones();
  DbProd();
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;
  await tests(rootUrl);
}