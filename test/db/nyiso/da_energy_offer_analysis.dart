library test.db.nyiso.da_energy_offer_analysis;

import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/da_energy_offer.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> getGenerators(String rootUrl) async {
  var location = Iso.newYork.preferredTimeZoneLocation;
  var month = Month.utc(2021, 1);

  var client = DaEnergyOffers(Client(), iso: Iso.newYork, rootUrl: rootUrl);
  var aux = await client
      .getDaEnergyOffers(Hour.beginning(TZDateTime(location, 2021, 1, 1, 15)));
  print(aux);
}

Future<void> main() async {
  initializeTimeZones();

  var rootUrl = 'http://127.0.0.1:8080';
  await getGenerators(rootUrl);
}
