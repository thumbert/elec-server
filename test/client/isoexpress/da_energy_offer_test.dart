library test.client.da_energy_offer_test;

import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/isoexpress/da_energy_offer.dart';

tests() async {
  Location location = getLocation('US/Eastern');
  var api = DaEnergyOfferApi(Client());
  group('API binding constraints:', () {
    test('get energy offers for hour 2017-07-01 16:00:00', () async {
      var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
      var aux = await api.getDaEnergyOffers(hour);
      expect(aux.length, 731);
      expect(aux.first, {
        'assetId': 10393,
        'Unit Status': 'ECONOMIC',
        'Economic Maximum': 14.9,
        'price': -150,
        'quantity': 10.5,
      });
    });
//    test('get da binding constraints data for 2 days', () async {
//      var aux = await api.getDaBindingConstraint('PARIS   O154          A LN');
//      expect(aux.length > 100, true);
//    });

  });
}

main() async {
  await initializeTimeZone();
  await tests();
}
