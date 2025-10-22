import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  group('Competitive Offer Rate tests', () {
    var archive = RetailSuppliersOffersArchive();
    var aux = json.decode(
        File('${archive.dir}/2022-12-04_ct.json').readAsStringSync()) as List;
    var allData = aux.cast<Map<String, dynamic>>();

    test('Process all CT offers as of 2022-12-04', () {
      var offers = allData.map((e) => CtSupplyOffer.toMongo(e)).toList();
      expect(offers.length, 41);
      var groups = groupBy(offers, (Map e) => e['offerId']);
      print(groups.keys.length);
      print('here');
    });

    // test('Eversource CT', () {
    //   var offer0 = CtSupplyOffer.fromRawData(allData[0]);
    //   expect(offer0.supplierName, 'NRG Business');
    //   expect(offer0.countOfBillingCycles, 24);
    //   expect(offer0.offerType, 'Fixed');
    //   expect(offer0.minimumRecs, 0.33);
    //   expect(offer0.rate, 168.9);
    //   expect(offer0.rateUnit, '\$/MWh');
    //   expect(offer0.offerPostedOnDate, Date.utc(2022,10,28));
    //   expect(offer0.offerId, 'ct-49486');
    // });

    // test('Massachussetts offer table', () {
    //   var file = File('test/db/utilities/retail_offers/offer_table_ma.html');
    //   var document = parse(file.readAsStringSync());
    //
    //   var table = document.querySelector('.energy-provider-table');
    //   var tbody = table!.querySelector('tbody');
    //   var rows = tbody!.querySelectorAll('tr');
    //
    //   var offers = <Map<String,dynamic>>[];
    //   for (var row in rows) {
    //     var xs = row.querySelectorAll('td');
    //     var supplier = xs[0].querySelector('img')!.attributes['title'];
    //     var termDetails = xs[1].querySelector('span')!.text;
    //     var countOfCycles = int.parse(termDetails.split(' ').first);
    //     var planFeatures = xs[2].querySelectorAll('div').map((e) => e.text).toList();
    //     var rate = num.parse(xs[3].querySelector('span')!.text.split(' ').first)*10;
    //     var one = {
    //         'region': 'ISONE',
    //         'state': 'MA',
    //         'loadZone': 'NEMA',
    //         'accountType': 'Residential',
    //         'countOfBillingCycles': countOfCycles,
    //         'minimumRecs': double.nan,
    //         'supplierName': supplier,
    //         'termDetails': termDetails,
    //         'planFeatures': planFeatures,
    //         'rate': rate,
    //         'rateUnit': '\$/MWh',
    //     };
    //     one['uniqueId'] = base64.encode(one.toString().codeUnits);
    //     offers.add(one);
    //   }
    //
    //   print(tbody);
    //
    //
    // }, solo: true);
  });
}

Future<void> main() async {
  initializeTimeZones();

  // await getMaOffers();

  await tests();
}
