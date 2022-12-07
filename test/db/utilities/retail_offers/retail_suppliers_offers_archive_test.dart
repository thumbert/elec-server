library test.utilities.rate_board_test;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:elec_server/client/utilities/retail_suppliers_offers.dart';
import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  // var archive = RetailSuppliersOffersArchive();
  // await archive.saveCurrentRatesToFile();

  group('Api tests competitive offers', () {
    test('get offers for region ISONE', () async {
      var aux = await get(Uri.parse(
          '$rootUrl/retail_suppliers/v1/offers/region/isone/start/2022-01-01/end/2022-12-04'));
      var data = json.decode(aux.body) as List;
      var x0 = data.firstWhere((e) => e['offerId'] == 'ct-49486')
          as Map<String, dynamic>;
      expect(x0.keys.toSet(), {
        'offerId',
        'region',
        'state',
        'utility',
        'accountType',
        'countOfBillingCycles',
        'minimumRecs',
        'offerType',
        'rate',
        'rateUnit',
        'supplierName',
        'offerPostedOnDate',
      });
      expect(x0['rate'], 168.9);
    });
  });

  ///
  ///
  group('Retail suppliers offers client tests', () {
    var client = RetailSuppliersOffers(Client(), rootUrl: rootUrl);
    var term = Term.parse('1Jan22-4Dec22', UTC);
    late List<RetailSupplyOffer> offers;
    setUp(() async {offers = await client.getOffersForRegionTerm('ISONE', term);});
    test('get ISONE offers', () async {
      var x0 = offers.firstWhere((e) => e.offerId == 'ct-49486');
      expect(x0.rate, 168.9);
      expect(x0.supplierName, 'NRG Business');
    });

    test('get current offers as of a given date', () {
      var o1 = RetailSuppliersOffers.getCurrentOffers(offers, Date.utc(2022, 11, 17));
      expect(o1
          .where((e) => e.supplierName == 'Constellation NewEnergy, Inc.')
          .toList().length, 0);
      // as of 2022-11-28 there are new offers
      var o2 = RetailSuppliersOffers.getCurrentOffers(offers, Date.utc(2022, 11, 28));
      expect(o2
          .where((e) => e.supplierName == 'Constellation NewEnergy, Inc.')
          .toList().length, 4);
    });

  });
}

Future<void> main() async {
  initializeTimeZones();
  var rootUrl = 'http://127.0.0.1:8080';
  await tests(rootUrl);
}
