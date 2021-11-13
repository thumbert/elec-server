library test.db.isone.masked_ids_test;

import 'package:elec_server/client/isone/masked_ids.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl) async {
  var api = IsoNewEnglandMaskedAssets(Client(), rootUrl: rootUrl);
  group('ISO New England masked assets:', () {
    test('get all masked generators', () async {
      var data = await api.getAssets(type: 'generator');
      var my9 = data.firstWhere((e) => e['ptid'] == 1616);
      expect(my9['name'], 'MYSTIC 9');
      expect(my9['Masked Asset ID'], 72020);
    });
    test('get all masked participants', () async {
      var data = await api.getAssets(type: 'participant');
      var nxt =
          data.firstWhere((e) => e['name'] == 'NextEra Energy Power Marketing');
      expect(nxt['Masked Participant ID'], 206845);
    });
    test('get all masked locations', () async {
      var data = await api.getAssets(type: 'location');
      var hub = data.firstWhere((e) => e['ptid'] == 4000);
      expect(hub['Masked Location ID'], 75309);
    });
  });
}

void main() async {
  initializeTimeZones();

  //dotenv.load('.env/test.env');
  var rootUrl = 'http://localhost:8080';
  await tests(rootUrl);
}
