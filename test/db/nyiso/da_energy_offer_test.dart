library test.db.nyiso.da_energy_offer_test;

import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/api/api_energyoffers.dart';
import 'package:elec_server/client/da_energy_offer.dart' as eo;
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/nyiso/da_energy_offer.dart';
import 'package:elec/elec.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:path/path.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = NyisoDaEnergyOfferArchive();
  group('NYISO energy offer db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('test filenames, urls', () async {
      var month = Month.utc(2021, 1);
      var file = archive.getCsvFile(month.startDate);
      expect(basename(file.path), '20210101biddata_genbids.csv');
    });
    test('read file for 2021-01', () async {
      var file = archive.getZipFileForMonth(Month.utc(2021, 1));
      var data = archive.processFile(file);
      expect(data.length, 8873);
      expect(data.first.keys.toSet(),
          {'date', 'Masked Lead Participant ID', 'Masked Asset ID', 'hours'});
      // Athens 1
      var a1 = data.firstWhere(
          (e) => e['Masked Asset ID'] == 98347750 && e['date'] == '2021-01-01');
      expect((a1['hours'] as List).first.keys.toSet(), {
        'Economic Maximum',
        'Economic Minimum',
        'Startup Cost',
        'price',
        'quantity',
        '10 Min Spin Cost',
        '30 Min Spin Cost',
        'Regulation MW',
        'Regulation Cost',
        'Regulation Movement Cost'
      });
      var mw = a1['hours'].first['quantity'] as List;
      var prices = a1['hours'].first['price'] as List;
      expect(mw.length, 9); // 9 pq pairs, not incremental but cumulative!
      expect(prices.length, 9);
      // incremental quantities
      expect(mw.take(3).toList(), [
        310.4,
        9.4,
        9.4,
      ]);
    });

    test('make gz file for 2023-03', () {
      var res = archive.makeGzFileForMonth(Month.utc(2023, 3));
      expect(res, 0);
      // ' 01MAR2023:05:00:00';
    });

    /// Athens 1,2,3: 98347750, 28347750, 38347750
    /// 35855750 self-commits in DAM on 1/1/2021, 175 MW for a few hours in the middle of the day ...
    ///
  });
  group('NYISO energy offers API tests: ', () {
    var api = DaEnergyOffers(archive.db, iso: Iso.newYork);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('get energy offers for one hour', () async {
      var data = await api.getEnergyOffers('20210101', '16');
      expect(data.length, 810);

      var a1 = data.where((e) => e['assetId'] == 98347750).toList();
      expect(a1.length, 9); // 9 segments
      expect(a1.first.keys.toSet(), {
        'assetId',
        'Economic Maximum',
        'price',
        'quantity',
      });
      expect(a1.first['Economic Maximum'], 381);
      expect(a1.first['quantity'], 306.3);
      expect(a1[1]['quantity'], 9.3);
    });
    test('get stack for one hour', () async {
      var data = await api.getGenerationStack('20210101', '16');
      expect(data.length, 810);
    });
    test('get assets one day', () async {
      var data = await api.assetsByDay('20210101');
      expect(data.length, 287);
    });
    // test('get Economic Maximum for one day', () async {
    //   var data = await api.oneDailyVariable(
    //       'Economic Maximum', '20210101', '20210101');
    //   expect(data.length, 308);
    // }, solo: true);
    test('get energy offers for one asset between a start/end date', () async {
      var _data = await api.getEnergyOffersForAssetId(
          '98347750', '20210101', '20210103');
      expect(_data.length, 3);
      var url =
          '$rootUrl/nyiso/da_energy_offers/v1/assetId/98347750/start/2021-01-01/end/2021-01-03';
      var res = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.length, 3);
      expect(data.first.keys.toSet(), {'date', 'hours'});
    });
  });

  group('NYISO energy offers, Rust API', () {
    test('get offers', () async {
      final ids = [35537750, 55537750, 67537750, 75537750];
      final url = [
        dotenv.env['RUST_SERVER'],
        '/nyiso/energy_offers/dam/energy_offers',
        '/start/2024-03-01',
        '/end/2024-03-01',
        '?masked_asset_ids=${ids.join(',')}'
      ].join();
      var res = await http.get(Uri.parse(url));
      var data = json.decode(res.body) as List;
      expect(data.length, 672);
      expect(data.first, {
        'masked_asset_id': 35537750,
        'timestamp_s': 1709269200,
        'segment': 0,
        'price': 15.6,
        'quantity': 150.0
      });
    });
  });

  group('NYISO energy offers client tests: ', () {
    var client =
        eo.DaEnergyOffers(http.Client(), iso: Iso.newYork, rootUrl: rootUrl);
    test('get energy offers for hour 2021-01-01 16:00:00', () async {
      var hour = Hour.beginning(
          TZDateTime(Iso.newYork.preferredTimeZoneLocation, 2021, 1, 1, 16));
      var aux = await client.getDaEnergyOffers(hour);
      expect(aux.length, 810);
      var a1 = aux.firstWhere((e) => e['assetId'] == 98347750);
      expect(a1, {
        'assetId': 98347750,
        'Economic Maximum': 381.0,
        'price': 27.21,
        'quantity': 306.3,
      });
    });
    test('get generation stack for hour 2017-07-01 16:00:00', () async {
      var hour = Hour.beginning(
          TZDateTime(Iso.newYork.preferredTimeZoneLocation, 2021, 1, 1, 16));
      var aux = await client.getGenerationStack(hour);
      expect(aux.length, 810);
      expect(aux.first, {
        'assetId': 37796180,
        'price': -999.0,
        'quantity': 50.0,
      });
    });
    test('get asset ids and participant ids for 2021-01-03', () async {
      var aux = await client.assetsForDay(Date.utc(2021, 1, 3));
      expect(aux.length, 282);
      aux.sort((a, b) =>
          (a['Masked Asset ID'] as int).compareTo(b['Masked Asset ID']));
      expect(aux.first, {
        'Masked Asset ID': 36180,
        'Masked Lead Participant ID': 19092750,
      });
    });
    test('get energy offers for asset 98347750 between 2 dates', () async {
      var data = await client.getDaEnergyOffersForAsset(
          98347750, Date.utc(2021, 1, 1), Date.utc(2021, 1, 3));
      expect(data.length, 3);
      expect(data.first.keys.toSet(), {'date', 'hours'});
    });
    test('get energy offers price/quantity timeseries for asset 98347750',
        () async {
      var data = await client.getDaEnergyOffersForAsset(
          98347750, Date.utc(2021, 1, 1), Date.utc(2021, 1, 3));
      var out = eo.priceQuantityOffers(data, iso: Iso.newYork);
      expect(out.length, 9); // there are 9 segments
      expect(out.first.first.toString(),
          '[2021-01-01 00:00:00.000-0500, 2021-01-01 01:00:00.000-0500) -> {price: 27.45, quantity: 310.4}');
      expect(
          out[1].first.toString(), // second segment is incremental
          '[2021-01-01 00:00:00.000-0500, 2021-01-01 01:00:00.000-0500) -> {price: 28.0, quantity: 9.4}');
    });
    test('get average energy offers price timeseries for asset 98347750',
        () async {
      var data = await client.getDaEnergyOffersForAsset(
          98347750, Date.utc(2021, 1, 1), Date.utc(2021, 1, 3));
      var pqOffers = eo.priceQuantityOffers(data, iso: Iso.newYork);
      var out = eo.averageOfferPrice(pqOffers);
      expect(out.length, 72);
      expect(out.first.toString(),
          '[2021-01-01 00:00:00.000-0500, 2021-01-01 01:00:00.000-0500) -> {price: 27.93945595854924, quantity: 385.99999999999983}');
    });
  });
}

void main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name} (${record.time.toString().substring(0, 19)}) ${record.message}');
  });
  DbProd();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;
  tests(rootUrl);

  // print(NyisoDaEnergyOfferArchive.columns.entries
  //     .map((e) => '    "${e.key}" ${e.value},')
  //     .join('\n'));

  // final home = Platform.environment['HOME'];
  // final con =
  //     Connection('$home/Downloads/Archive/Nyiso/nyiso_energy_offers.duckdb');
  // final months = Month(2024, 2, location: IsoNewEngland.location)
  //     .upTo(Month(2024, 3, location: IsoNewEngland.location));
  // NyisoDaEnergyOfferArchive().updateDuckDb(months: months, con: con);
  // con.close();
}
