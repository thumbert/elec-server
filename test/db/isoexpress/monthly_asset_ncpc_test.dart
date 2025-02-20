library test.db.isoexpress.monthly_ncpc_asset_test;

import 'package:elec/risk_system.dart';
import 'package:elec_server/api/isoexpress/api_isone_monthly_asset_ncpc.dart';
import 'package:elec_server/client/isoexpress/monthly_asset_ncpc.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';

Future<void> tests(String rootUrl) async {
  final archive = getIsoneMonthlyAssetNcpcArchive();
  group('Monthly NCPC by asset db tests:', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read file for 2019-01', () async {
      var file = archive.getFilename(Month.utc(2019, 1));
      var data = archive.processFile(file);
      expect(data.length, 481);
      expect(data.first, {
        'month': '2019-01',
        'assetId': 321,
        'name': 'MANCHESTER 10/10A CC',
        'zoneId': 4005,
        'daNcpc': 0,
        'rtNcpc': 628.87,
      });
    });
    test('read empty file for 2022-12', () {
      var file = archive.getFilename(Month.utc(2022, 12));
      var data = archive.processFile(file);
      expect(data.isEmpty, true);
    });
  });
  group('Monthly NCPC by asset API tests:', () {
    var api = ApiMonthlyAssetNcpc(archive.dbConfig.db);
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('Get NCPC for all assets Jan19-Mar19', () async {
      var res = await api.apiGetAllAssets('2019-01', '2019-03');
      expect(res.length, 1435);
      expect(res.first, {
        'month': '2019-01',
        'assetId': 321,
        'name': 'MANCHESTER 10/10A CC',
        'zoneId': 4005,
        'daNcpc': 0,
        'rtNcpc': 628.87,
      });
    });
    test('Get the monthly NCPC payments for one asset', () async {
      var res = await api.apiGetAsset('1616', '2019-01', '2021-06');
      expect(res.length, 30);
      expect(res.first, {
        'month': '2019-01',
        'daNcpc': 0,
        'rtNcpc': 9170.94,
      });
    });
  });
  group('Monthly asset ncpc client tests:', () {
    var client = MonthlyAssetNcpc(http.Client(), rootUrl: rootUrl);
    var data = <Map<String, dynamic>>[];
    setUp(() async {
      data = await client.getAllAssets(Month.utc(2021, 1), Month.utc(2021, 6));
    });
    test('data structure', () async {
      expect(data.length, 7984);
      var first = data.first;
      expect(first, {
        'month': '2021-01',
        'assetId': 321,
        'name': 'MANCHESTER 10/10A CC',
        'zoneId': 4005,
        'market': Market.da,
        'value': 0,
      });
    });
    test('aggregation default, return one value', () {
      var out = client.summary(data,
          zoneId: null,
          byZoneId: false,
          market: null,
          byMarket: false,
          assetName: null,
          byAssetName: false,
          byMonth: false);
      expect(out.length, 1);
      expect(out.first['value'], 15406022);
    });
    test('aggregation by zone', () {
      var out = client.summary(data,
          zoneId: null,
          byZoneId: true,
          market: null,
          byMarket: false,
          assetName: null,
          byAssetName: false,
          byMonth: false);
      expect(out.length, 8);
      expect(out.first, {
        'zone': 4005,
        'value': 1431800,
      });
    });
    test('filter by zone: 4005 ', () {
      var out = client.summary(data,
          zoneId: 4005,
          byZoneId: true,
          market: null,
          byMarket: false,
          assetName: null,
          byAssetName: false,
          byMonth: false);
      expect(out.length, 1);
      expect(out.first, {
        'zone': 4005,
        'value': 1431800,
      });
    });
    test('filter by zone: 4005, byMonth: true ', () {
      var out = client.summary(data,
          zoneId: 4005,
          byZoneId: true,
          market: null,
          byMarket: false,
          assetName: null,
          byAssetName: false,
          byMonth: true);
      expect(out.length, 6);
      expect(out.first, {
        'zone': 4005,
        'month': '2021-01',
        'value': 256270,
      });
    });
    test('filter by zone: 4005, byMarket: true, byMonth: true ', () {
      var out = client.summary(data,
          zoneId: 4005,
          byZoneId: true,
          market: null,
          byMarket: true,
          assetName: null,
          byAssetName: false,
          byMonth: true);
      expect(out.length, 12);
      expect(out.first, {
        'zone': 4005,
        'market': Market.da,
        'month': '2021-01',
        'value': 57852,
      });
    });
    test('filter by assetName: "MYSTIC 9", byMonth: true ', () {
      var out = client.summary(data,
          zoneId: null,
          byZoneId: false,
          market: null,
          byMarket: false,
          assetName: 'MYSTIC 9',
          byAssetName: false,
          byMonth: true);
      expect(out.length, 6);
      expect(out.first, {
        'month': '2021-01',
        'value': 11111,
      });
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  DbProd();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;

  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // await MonthlyAssetNcpcArchive().setupDb();

  await tests(rootUrl);
}
