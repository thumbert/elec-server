library test.utilities.retail_offers.retail_supply_offer_rate_test;

import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  group('Competitive Offer Rate tests', () {
    var archive = RetailSuppliersOffersArchive();
    var aux = json.decode(File('${archive.dir}/2022-12-04_ct.json').readAsStringSync());
    var allData = aux.cast<Map<String,dynamic>>();

    test('Process all CT offers as of 2022-12-04', () {
      var offers = allData.map((e) => CtSupplyOffer.fromRawData(e)).toList();
      expect(offers.length, 41);
    });

    test('Eversource CT', () {
      var offer0 = CtSupplyOffer.fromRawData(allData[0]);
      expect(offer0.supplierName, 'NRG Business');
      expect(offer0.countOfBillingCycles, 24);
      expect(offer0.offerType, 'Fixed');
      expect(offer0.minimumRecs, 0.33);
      expect(offer0.rate, 168.9);
      expect(offer0.rateUnit, '\$/MWh');
      expect(offer0.offerPostedOnDate, Date.utc(2022,10,28));
      expect(offer0.offerId, 'ct-49486');
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}