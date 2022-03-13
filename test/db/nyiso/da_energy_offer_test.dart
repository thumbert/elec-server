library test.db.nyiso.da_energy_offer_test;

import 'dart:convert';
import 'dart:io';
import 'package:elec_server/api/api_energyoffers.dart';
import 'package:elec_server/client/da_energy_offer.dart' as eo;
import 'package:elec_server/src/db/nyiso/da_energy_offer.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:path/path.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = NyisoDaEnergyOfferArchive();
  var location = getLocation('America/New_York');
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
      var a1 = data.firstWhere((e) => e['Masked Asset ID'] == 98347750
          && e['date'] == '2021-01-01');
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
      expect(mw.length, 9);     // 9 pq pairs
      expect(prices.length, 9);
      expect(mw.take(3).toList(), [
        310.4,	319.8,	329.2,
      ]);
    });
    /// Athens 1,2,3: 98347750, 28347750, 38347750
    /// 35855750 self-commits in DAM on 1/1/2021, 175 MW for a few hours in the middle of the day ...
    ///
  });
  group('NYISO energy offers API tests: ', () {
    var api = DaEnergyOffers(archive.db, iso: Iso.newYork);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    // test('get energy offers for one hour', () async {
    //   var data = await api.getEnergyOffers('20210101', '16');
    //   expect(data.length, 733);
    //
    //   var a87105 = data.firstWhere((e) => e['assetId'] == 87105);
    //   expect(a87105['Economic Maximum'], 35);
    //   expect(a87105['quantity'], 9999);
    // });
    // test('get stack for one hour', () async {
    //   var data = await api.getGenerationStack('20170701', '16');
    //   expect(data.length, 698);
    // });
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
      var data =
      await api.getEnergyOffersForAssetId('98347750', '20210101', '20210103');
      expect(data.length, 3);
      var url = '$rootUrl/nyiso/da_energy_offers/v1/assetId/98347750/start/2021-01-01/end/2021-01-02';


    });
  });

  group('NYISO energy offers client tests: ', () {
    var client = eo.DaEnergyOffers(http.Client(), iso: Iso.newYork, rootUrl: rootUrl);
    // test('get energy offers for hour 2017-07-01 16:00:00', () async {
    //   var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
    //   var aux = await client.getDaEnergyOffers(hour);
    //   expect(aux.length, 731);
    //   var e10393 = aux.firstWhere((e) => e['assetId'] == 10393);
    //   expect(e10393, {
    //     'assetId': 10393,
    //     'Unit Status': 'ECONOMIC',
    //     'Economic Maximum': 14.9,
    //     'price': -150,
    //     'quantity': 10.5,
    //   });
    // });
    // test('get generation stack for hour 2017-07-01 16:00:00', () async {
    //   var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
    //   var aux = await client.getGenerationStack(hour);
    //   expect(aux.length, 696);
    //   expect(aux.first, {
    //     'assetId': 10393,
    //     'Unit Status': 'ECONOMIC',
    //     'Economic Maximum': 14.9,
    //     'price': -150,
    //     'quantity': 10.5,
    //   });
    // });
    // test('get asset ids and participant ids for 2017-07-01', () async {
    //   var aux = await client.assetsForDay(Date.utc(2017, 7, 1));
    //   expect(aux.length, 308);
    //   aux.sort((a, b) =>
    //       (a['Masked Asset ID'] as int).compareTo(b['Masked Asset ID']));
    //   expect(aux.first, {
    //     'Masked Asset ID': 10393,
    //     'Masked Lead Participant ID': 698953,
    //   });
    // });
    test('get energy offers for asset 41406 between 2 dates', () async {
      var data = await client.getDaEnergyOffersForAsset(
          98347750, Date.utc(2021, 1, 1), Date.utc(2021, 1, 2));
      expect(data.length, 2);
    }, solo: true);
    test('get energy offers price/quantity timeseries for asset 41406 ',
            () async {
          var data = await client.getDaEnergyOffersForAsset(
              41406, Date.utc(2018, 4, 1), Date.utc(2018, 4, 1));
          var out = eo.priceQuantityOffers(data);
          expect(out.length, 5);
          expect(out.first.first.toString(),
              '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 15.44, quantity: 332}');
        });
    test('get average energy offers price timeseries for asset 41406 ',
            () async {
          var data = await client.getDaEnergyOffersForAsset(
              41406, Date.utc(2018, 4, 1), Date.utc(2018, 4, 1));
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

  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);

}
