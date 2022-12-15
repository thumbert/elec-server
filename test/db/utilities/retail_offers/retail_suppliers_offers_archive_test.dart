library test.utilities.rate_board_test;

import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/api/utilities/api_retail_suppliers_offers.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:elec_server/client/utilities/retail_suppliers_offers.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  // var dbConfig = ComponentConfig(
  //     host: '127.0.0.1',
  //     dbName: 'retail_suppliers',
  //     collectionName: 'historical_offers_test');
  // var archive = RetailSuppliersOffersArchive(dbConfig: dbConfig);
  // group('DB tests', () {
  //   setUp(() async => await archive.dbConfig.db.open());
  //   tearDown(() async {
  //     await archive.dbConfig.db.close();
  //     // dbConfig.db.dropCollection('historical_offers_test');
  //   });
  //   test('test insertion', () async {
  //     await dbConfig.coll.remove({}); // start with a new slate
  //     /// insert one date
  //     var file = File(join(archive.dir, '2022-12-04_ct.json'));
  //     var aux1204 = archive.processFile(file);
  //     var data1204 = aux1204
  //         .where((e) =>
  //             e['utility'] == 'United Illuminating' &&
  //             e['accountType'] == 'Residential' &&
  //             e['countOfBillingCycles'] == 12 &&
  //             e['supplierName'] == 'XOOM Energy CT, LLC')
  //         .toList();
  //     var offerIds1204 = data1204.map((e) => e['offerId']).toList()..sort();
  //     print('Offers 12/04: $offerIds1204'); // 3 offers
  //     await archive.insertData(data1204);
  //     var docs1204 = await archive.dbConfig.coll.find().toList();
  //     expect(docs1204.length, 3);
  //
  //     /// insert date 12/11
  //     var aux1211 =
  //         archive.processFile(File(join(archive.dir, '2022-12-11_ct.json')));
  //     var data1211 = aux1211
  //         .where((e) =>
  //             e['utility'] == 'United Illuminating' &&
  //             e['accountType'] == 'Residential' &&
  //             e['countOfBillingCycles'] == 12 &&
  //             e['supplierName'] == 'XOOM Energy CT, LLC')
  //         .toList();
  //     var offerIds1211 = data1211.map((e) => e['offerId']).toList()..sort();
  //     print(
  //         'Offers 12/11: $offerIds1211'); // 3 offers, one offer new, one previous offer gone
  //     await archive.insertData(data1211);
  //     var docs1211 = await archive.dbConfig.coll.find().toList();
  //     expect(docs1211.length, 4);
  //
  //     /// this offer in still in the 12/11 file
  //     var d47216 = docs1211.firstWhere((e) => e['offerId'] == 'ct-47216');
  //     expect(d47216['offerPostedOnDate'], '2022-07-01');
  //     expect(d47216['firstDateOnWebsite'], '2022-12-04');
  //     expect(d47216['lastDateOnWebsite'], '2022-12-11');
  //
  //     /// this offer is gone from the 12/11 file
  //     var d50111 = docs1211.firstWhere((e) => e['offerId'] == 'ct-50111');
  //     expect(d50111['offerPostedOnDate'], '2022-12-01');
  //     expect(d50111['firstDateOnWebsite'], '2022-12-04');
  //     expect(d50111['lastDateOnWebsite'], '2022-12-04');
  //
  //     /// this is the new offer in the 12/11 file
  //     var d50191 = docs1211.firstWhere((e) => e['offerId'] == 'ct-50191');
  //     expect(d50191['offerPostedOnDate'], '2022-12-05');
  //     expect(d50191['firstDateOnWebsite'], '2022-12-11');
  //     expect(d50191['lastDateOnWebsite'], '2022-12-11');
  //
  //     /// this offer is in the 12/11 file
  //     var d50116 = docs1211.firstWhere((e) => e['offerId'] == 'ct-50116');
  //     expect(d50116['offerPostedOnDate'], '2022-12-01');
  //     expect(d50116['firstDateOnWebsite'], '2022-12-04');
  //     expect(d50116['lastDateOnWebsite'], '2022-12-11');
  //
  //     /// insert date 12/14
  //     var aux1214 =
  //         archive.processFile(File(join(archive.dir, '2022-12-14_ct.json')));
  //     var data1214 = aux1214
  //         .where((e) =>
  //             e['utility'] == 'United Illuminating' &&
  //             e['accountType'] == 'Residential' &&
  //             e['countOfBillingCycles'] == 12 &&
  //             e['supplierName'] == 'XOOM Energy CT, LLC')
  //         .toList();
  //     var offerIds1214 = data1214.map((e) => e['offerId']).toList()..sort();
  //     print(
  //         'Offers 12/14: $offerIds1214'); //
  //     await archive.insertData(data1214);
  //     var docs1214 = await archive.dbConfig.coll.find().toList();
  //     expect(docs1214.length, 4);
  //   }, solo: true);
  // });

  group('Api tests competitive offers', () {
    // var api = ApiRetailSuppliersOffers(archive.dbConfig.db);
    // setUp(() async => await archive.dbConfig.db.open());
    // tearDown(() async => await archive.dbConfig.db.close());

    test('get offers for region ISONE', () async {
      // var xs = await api.getOffersForRegion(
      //     'ISONE', 'CT', Date.utc(2022, 1, 1), Date.utc(2022, 12, 4));
      // var constellation = xs
      //     .where((e) => e['supplierName'].startsWith('Constellation'))
      //     .toList();
      // expect(constellation.length, 4);

      var aux = await get(Uri.parse(
          '$rootUrl/retail_suppliers/v1/offers/region/isone/start/2022-01-01/end/2022-12-14'));
      var data = json.decode(aux.body) as List;
      var x0 = data.firstWhere((e) => e['offerId'] == 'ct-47176')
          as Map<String, dynamic>;
      expect(x0.keys.toSet(), {
        'offerId',
        'region',
        'state',
        'loadZone',
        'utility',
        'accountType',
        'rateClass',
        'countOfBillingCycles',
        'minimumRecs',
        'offerType',
        'rate',
        'rateUnit',
        'supplierName',
        'planFees',
        'planFeatures',
        'offerPostedOnDate',
        'firstDateOnWebsite',
        'lastDateOnWebsite',
      });
      expect(x0['rate'], 209.9);
    });
  });

  ///
  ///
  group('Retail suppliers offers client tests', () {
    var client = RetailSuppliersOffers(Client(), rootUrl: rootUrl);
    var term = Term.parse('1Jan22-14Dec22', UTC);
    late List<RetailSupplyOffer> offers;
    setUp(() async {
      offers = await client.getOffersForRegionTerm('ISONE', term); // all states
    });
    test('get ISONE offers', () async {
      var x0 = offers.firstWhere((e) => e.offerId == 'ct-47176');
      expect(x0.rate, 209.9);
      expect(x0.supplierName, 'NRG Business');

      var constellation = offers
          .where((e) =>
              e.state == 'CT' &&
              e.utility == 'Eversource' &&
              e.supplierName.startsWith('Constellation'))
          .toList();
      expect(constellation.length, 2);
    });

    test('get current offers as of a given date', () {
      var o1 = RetailSuppliersOffers.getCurrentOffers(
          offers, Date.utc(2022, 11, 17));

      /// No Constellation offers as of 2022-11-17
      expect(
          o1
              .where((e) => e.supplierName == 'Constellation NewEnergy, Inc.')
              .toList()
              .length,
          0);
      // as of 2022-11-28 there are 4 new offers from Constellation
      var o2 = RetailSuppliersOffers.getCurrentOffers(
          offers, Date.utc(2022, 11, 28));
      expect(
          o2
              .where((e) => e.supplierName == 'Constellation NewEnergy, Inc.')
              .toList()
              .length,
          4);
    });

    test('XOOM offers for United Illuminating as of 2022-12-04', () {
      var offersXoom = offers
          .where((e) =>
              e.state == 'CT' &&
              e.utility == 'United Illuminating' &&
              e.accountType == 'Residential' &&
              e.countOfBillingCycles == 12 &&
              e.supplierName == 'XOOM Energy CT, LLC')
          .toList();

      var xs = RetailSuppliersOffers.getCurrentOffers(
          offersXoom, Date.utc(2022, 12, 4));

      /// Two identical offers except for the incentive.  One offer gives you
      /// airline miles.
      expect(xs.length, 2);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  DbProd();
  var rootUrl = 'http://127.0.0.1:8080';
  await tests(rootUrl);

  // var archive = RetailSuppliersOffersArchive();
  // await archive.saveCurrentRatesToFile(states: ['CT', 'MA']);
}
