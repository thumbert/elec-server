library test.db.lng.lib_stjohns_test;

import 'package:elec_server/src/db/lng/lib_stjohns.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl) async {
  var sj = StJohnsVessels();
  group('StJohns vessels tests:', () {
    test('read expected vessels in port', () async {
      var data = await sj.getExpectedVessels();
      expect(data.length > 1, true);
      expect(data.first.keys.toSet(), {
        'VESSEL_NAME', 'SHIP_LINE', 'BERTH', 'AGENT', 'ETA', 'CARGO_ACTIVITY',
      });
    });
    test('read current vessels in port', () async {
      var data = await sj.getCurrentVessels();
      expect(data.length > 1, true);
      expect(data.first.keys.toSet(), {
        'VESSEL_NAME', 'SHIP_LINE', 'BERTH', 'AGENT',
        'DATE_OF_ARRIVAL', 'CARGO_ACTIVITY',
      });
    });
    test('read file with ships', () {
      var ships = sj.readArchiveFile();
      expect(ships.isEmpty, true);
    });
  });
}

/// Notify if there is a new LNG ship expected in port
Future<void> notify() async {
  var sj = StJohnsVessels();
  var expectedVessels = await sj.getExpectedVessels();
  var lngVessels = expectedVessels.where(sj.filterLngShips).toList();

  if (lngVessels.isNotEmpty) {
    // check if it's a new ship
    for (var vessel in lngVessels) {
      var ship = Ship.fromMap(vessel);
      if (sj.isNewShip(ship)) {
        print('New ship found!  Send notification!');
        print(vessel);
        sj.saveShipToArchive(ship);
      }
    }
  }

}


void main() async {
  initializeTimeZones();
  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
