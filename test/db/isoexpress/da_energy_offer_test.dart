library test.db.isoexpress.da_energy_offers_test;

import 'dart:io';

import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/api/api_energyoffers.dart';
import 'package:elec_server/client/isoexpress/energy_offer.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/client/da_energy_offer.dart' as eo;

import '../utilities/customer_counts_test.dart';

Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  var archive = DaEnergyOfferArchive();

  group('ISONE DA energy offers db tests: ', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('DA energy offers report, DST day spring', () {
      var file = archive.getFilename(Date.utc(2017, 3, 12));
      var res = archive.processFile(file);
      expect(res.first['hours'].length, 23);
    });
    test('DA hourly lmp report, DST day fall', () {
      var file = archive.getFilename(Date.utc(2017, 11, 5));
      var res = archive.processFile(file);
      expect(res.first['hours'].length, 25);
    });
    // test('aggregate days', () {
    //   var out = archive.aggregateDays([Date.utc(2023, 5, 31)]);
    //   expect(out.length, 21813);
    //   expect(out.first.hour.start,
    //       TZDateTime(IsoNewEngland.location, 2023, 5, 31));
    //   expect(out.first.toCsv(),
    //       '2023-05-31T00:00:00.000-0400,20720,40320,0.0,93.5,93.5,7782.75,7782.75,7782.75,1648.49,0,49.07,93.5,0.0,87.0,ECONOMIC');
    // });
  });

  group('ISONE DA energy offers API tests: ', () {
    var api = DaEnergyOffers(archive.db, iso: Iso.newEngland);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('get energy offers for one hour', () async {
      var data = await api.getEnergyOffers('20170701', '16');
      expect(data.length, 731);

      var a87105 = data.firstWhere((e) => e['assetId'] == 87105);
      expect(a87105['Economic Maximum'], 35);
      expect(a87105['quantity'], 9999);
    });
    test('get stack for one hour', () async {
      var data = await api.getGenerationStack('20170701', '16');
      expect(data.length, 696);
    });
    test('get assets one day', () async {
      var data = await api.assetsByDay('20170701');
      expect(data.length, 308);
    });
    test('get Economic Maximum for one day', () async {
      var data = await api.oneDailyVariable(
          'Economic Maximum', '20170701', '20170701');
      expect(data.length, 308);
    });
    test('get energy offers for one asset between a start/end date', () async {
      var data =
          await api.getEnergyOffersForAssetId('41406', '20170701', '20170702');
      expect(data.length, 2);
    });
  });

  group('ISONE DA energy offers client tests: ', () {
    var client =
        eo.DaEnergyOffers(http.Client(), iso: Iso.newEngland, rootUrl: rootUrl);
    test('get energy offers for hour 2017-07-01 16:00:00', () async {
      var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
      var aux = await client.getDaEnergyOffers(hour);
      expect(aux.length, 731);
      var e10393 = aux.firstWhere((e) => e['assetId'] == 10393);
      expect(e10393, {
        'assetId': 10393,
        'Unit Status': 'ECONOMIC',
        'Economic Maximum': 14.9,
        'price': -150,
        'quantity': 10.5,
      });
    });
    test('get generation stack for hour 2017-07-01 16:00:00', () async {
      var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
      var aux = await client.getGenerationStack(hour);
      expect(aux.length, 696);
      expect(aux.first, {
        'assetId': 10393,
        'Unit Status': 'ECONOMIC',
        'Economic Maximum': 14.9,
        'price': -150,
        'quantity': 10.5,
      });
    });
    test('get asset ids and participant ids for 2017-07-01', () async {
      var aux = await client.assetsForDay(Date.utc(2017, 7, 1));
      expect(aux.length, 308);
      aux.sort((a, b) =>
          (a['Masked Asset ID'] as int).compareTo(b['Masked Asset ID']));
      expect(aux.first, {
        'Masked Asset ID': 10393,
        'Masked Lead Participant ID': 698953,
      });
    });
    test('get energy offers for asset 41406 between 2 dates', () async {
      var data = await client.getDaEnergyOffersForAsset(
          41406, Date.utc(2017, 7, 1), Date.utc(2017, 7, 2));
      expect(data.length, 2);
    });
    test('get energy offers price/quantity timeseries for asset 41406 ',
        () async {
      var data = await client.getDaEnergyOffersForAsset(
          41406, Date.utc(2018, 4, 1), Date.utc(2018, 4, 1));
      var out = eo.priceQuantityOffers(data, iso: Iso.newEngland);
      expect(out.length, 5);
      expect(out.first.first.toString(),
          '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 15.44, quantity: 332}');
    });
    test('get average energy offers price timeseries for asset 41406 ',
        () async {
      var data = await client.getDaEnergyOffersForAsset(
          41406, Date.utc(2018, 4, 1), Date.utc(2018, 4, 1));
      var pqOffers = eo.priceQuantityOffers(data, iso: Iso.newEngland);
      var out = eo.averageOfferPrice(pqOffers);
      expect(out.length, 24);
      expect(out.first.toString(),
          '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 16.59470909090909, quantity: 550}');
    });

    test('get average energy offers price timeseries for asset 11515',
        () async {
      /// DOREEN, is unavailable for the entire term
      var data = await client.getDaEnergyOffersForAsset(
          11515, Date.utc(2023, 5, 1), Date.utc(2023, 5, 30));
      var pqOffers = eo.priceQuantityOffers(data, iso: Iso.newEngland);
      var out = eo.averageOfferPrice(pqOffers);
      expect(out.isEmpty, true);
    });
  });

  // group('DuckDb functionality tests', () {
  //   late final Connection con;
  //   setUp(() {
  //     con = Connection(
  //         '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/energy_offers.duckdb',
  //         Config(accessMode: AccessMode.readOnly));
  //   });
  //   tearDown(() {
  //     con.close();
  //   });
  //   test('get offers for one unit', () {
  //     final term = Term.parse('1Jan23', IsoNewEngland.location);
  //     final offers = getEnergyOffers(con, term, Market.rt, [72020]);
  //     expect(offers.length, 120);
  //   });
  // });
}

void main() async {
  initializeTimeZones();
  //await DaEnergyOfferArchive().setupDb();

  print(
      '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/energy_offers.duckdb');

  // dotenv.load('.env/prod.env');
  await tests('http://127.0.0.1:8080');
}
