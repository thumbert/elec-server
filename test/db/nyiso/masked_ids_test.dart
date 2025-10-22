import 'package:elec/elec.dart';
import 'package:elec_server/client/masked_ids.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl) async {
  var api = MaskedIds(Client(), iso: Iso.newYork, rootUrl: rootUrl);
  group('NYISO masked assets:', () {
    test('get all masked generators', () async {
      var data = await api.getAssets(type: 'generator');
      var my9 = data.firstWhere((e) => e['ptid'] == 23668);
      expect(my9['name'], 'Athens 1');
      expect(my9['Masked Asset ID'], 98347750);
    });
    test('get all masked participants', () async {
      var data = await api.getAssets(type: 'participant');
      var nxt = data
          .firstWhere((e) => e['name'] == 'Dynegy Marketing and Trade, LLC');
      expect(nxt['Masked Participant ID'], 78710750);
    });
    test('get all masked locations', () async {
      var data = await api.getAssets(type: 'location');
      var zoneA = data.firstWhere((e) => e['ptid'] == 61752);
      expect(zoneA['Masked Location ID'], 65596180);
    });
  });
}

void main() async {
  initializeTimeZones();

  //dotenv.load('.env/test.env');
  var rootUrl = 'http://localhost:8080';
  await tests(rootUrl);
}
