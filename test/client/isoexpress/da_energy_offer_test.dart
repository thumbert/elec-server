library test.client.da_energy_offer_test;

import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/isoexpress/da_energy_offer.dart';

tests() async {
  Location location = getLocation('US/Eastern');
  var api = DaEnergyOffers(Client());
  group('DA Energy Offers client:', () {
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
    test('get generation stack for hour 2017-07-01 16:00:00', () async {
      var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
      var aux = await api.getGenerationStack(hour);
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
      var aux = await api.assetsForDay(Date(2017, 7, 1));
      expect(aux.length, 308);
      expect(aux.first, {
        'Masked Asset ID': 10393,
        'Masked Lead Participant ID': 698953,
      });
    });

    test('get last day in db', () async {
      var date = await api.lastDate();
      expect(date is Date, true);
    });



  });
}

main() async {
  await initializeTimeZone();
  await tests();
}
