library test.db.isoexpress.da_energy_offers_test;

import 'package:elec_server/api/isoexpress/api_isone_energyoffers.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/client/isoexpress/da_energy_offer.dart' as eo;

void tests() async {
  var shelfRootUrl = dotenv.env['SHELF_ROOT_URL'];
  var location = getLocation('America/New_York');
  var archive = DaEnergyOfferArchive();

  group('DA energy offers db tests: ', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('download 2018-02-01 and insert it', () async {
      var date = Date(2018, 2, 1);
      //await archive.downloadDay(date);
      var res = await archive.insertDay(date);
      expect(res, 0);
    });
    test('DA energy offers report, DST day spring', () {
      var file = archive.getFilename(Date(2017, 3, 12));
      var res = archive.processFile(file);
      expect(res.first['hours'].length, 23);
    });
    test('DA hourly lmp report, DST day fall', () {
      var file = archive.getFilename(Date(2017, 11, 5));
      var res = archive.processFile(file);
      expect(res.first['hours'].length, 25);
    });
  });

  group('DA energy offers API tests: ', () {
    var api = DaEnergyOffers(archive.db);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('get energy offers for one hour', () async {
      var data = await api.getEnergyOffers('20170701', '16');
      expect(data.length, 733);

      var a87105 = data.firstWhere((e) => e['assetId'] == 87105);
      expect(a87105['Economic Maximum'], 35);
      expect(a87105['quantity'], 9999);
    });
    test('get stack for one hour', () async {
      var data = await api.getGenerationStack('20170701', '16');
      expect(data.length, 698);
    });
    test('last day inserted', () async {
      var day = await api.lastDay();
      expect(Date.parse(day) is Date, true);
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

  group('DA energy offers client tests: ', () {
    var client = eo.DaEnergyOffers(http.Client(), rootUrl: shelfRootUrl);
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
      var aux = await client.assetsForDay(Date(2017, 7, 1));
      expect(aux.length, 308);
      aux.sort((a, b) =>
          (a['Masked Asset ID'] as int).compareTo(b['Masked Asset ID']));
      expect(aux.first, {
        'Masked Asset ID': 10393,
        'Masked Lead Participant ID': 698953,
      });
    });
    test('get last day in db', () async {
      var date = await client.lastDate();
      expect(date is Date, true);
    });
    test('get energy offers for asset 41406 between 2 dates', () async {
      var data = await client.getDaEnergyOffersForAsset(
          41406, Date(2017, 7, 1), Date(2017, 7, 2));
      expect(data.length, 2);
    });
    test('get energy offers price/quantity timeseries for asset 41406 ',
        () async {
      var data = await client.getDaEnergyOffersForAsset(
          41406, Date(2018, 4, 1), Date(2018, 4, 1));
      var out = eo.priceQuantityOffers(data);
      expect(out.length, 5);
      expect(out.first.first.toString(),
          '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 15.44, quantity: 332}');
    });
    test('get average energy offers price timeseries for asset 41406 ',
        () async {
      var data = await client.getDaEnergyOffersForAsset(
          41406, Date(2018, 4, 1), Date(2018, 4, 1));
      var pqOffers = eo.priceQuantityOffers(data);
      var out = eo.averageOfferPrice(pqOffers);
      expect(out.length, 24);
      expect(out.first.toString(),
          '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 16.59470909090909, quantity: 550}');
    });
  });
}

void main() async {
  initializeTimeZones();
  //await DaEnergyOfferArchive().setupDb();

  dotenv.load('.env/prod.env');
  tests();
}
