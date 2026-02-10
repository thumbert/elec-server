import 'dart:convert';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/api/cme/api_cme.dart';
import 'package:elec_server/client/marks/forward_marks2.dart';
import 'package:elec_server/src/db/cme/cme_energy_settlements.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:logging/logging.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  group('CME energy settlements db test:', () {
    var archive = CmeSettlementsEnergyArchive();
    test('get report date', () {
      var row0 =
          '        FINAL POST-CLEARING PRICES AS OF 04/28/2023 10:32 PM (CDT)';
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
    setUp(() async {
      await DbProd.cme.open();
    });
    tearDown(() async {
      await DbProd.cme.close();
    });
    test('get all curveIds', () async {
      var curveIds = await api.allCurveIds('2023-04-28');
      expect(curveIds.length > 1, true);
      expect(curveIds.contains('NG_TTF_USD_CME'), true);
    });
    test('get the price for one curveIds as of a given date', () async {
      var x = await api.getPrice('NG_TTF_USD_CME', '2023-04-28');
      expect(x.keys.toSet(), {'terms', 'values'});
    });
    test('get the strip data', () async {
      var x = await api.getStripData(
        curveName: 'NG_HENRY_HUB_CME',
        contractStart: Month.utc(2024, 1),
        contractEnd: Month.utc(2024, 2),
        start: Date.utc(2023, 1, 1),
        end: Date.utc(2023, 7, 27),
      );
      expect(x.length, 100);
      expect(x.first, ['2023-04-28', '2024-01', 3.877]);

      // with http
      var url = '$rootUrl/forward_marks/v2/price/curvename/NG_HENRY_HUB_CME'
          '/contract_start/2024-01/contract_end/2024-02'
          '/start/2023-01-01/end/2023-07-27';
      var res = await get(Uri.parse(url));
      var y = json.decode(res.body) as List;
      expect(y.length, 100);
      expect(y.first, ['2023-04-28', '2024-01', 3.877]);
    });
  });

  group('CME energy settlements client test:', () {
    var client = ForwardMarks2(rootUrl: rootUrl);
    test('get all curve ids', () async {
      var ids = await client.getCurveNames(
          asOfDate: Date.utc(2023, 7, 6), markType: MarkType.price);
      expect(ids.length > 3, true);
    });
    test('get price for one as of date', () async {
      var ts = await client.getPriceCurveForAsOfDate(
          asOfDate: Date.utc(2023, 7, 6),
          curveName: 'NG_HENRY_HUB_CME',
          location: UTC);
      expect(ts.length, 149);
      expect(ts.first, IntervalTuple<num>(Month.utc(2023, 8), 2.609));
    });
    test('get historical price for a strip', () async {
      var ts = await client.getCurveStrip(
        curveName: 'NG_HENRY_HUB_CME',
        strip: Term.parse('Jan24-Feb24', UTC),
        startDate: Date.utc(2023, 1, 1),
        endDate: Date.utc(2023, 7, 27),
        markType: MarkType.price,
        location: UTC,
        bucket: Bucket.atc,
      );
      expect(ts.length, 50);
      expect(ts.first, IntervalTuple<num>(Date.utc(2023, 4, 28), 3.82915));
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
