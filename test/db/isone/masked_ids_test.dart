library test.db.isone.masked_ids_test;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:elec/elec.dart';
import 'package:elec_server/api/api_masked_ids.dart';
import 'package:elec_server/client/masked_ids.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl) async {
  group('ISO New England masked assets api tests:', () {
    var db = DbProd.isone;
    var api = ApiMaskedIds(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get all', () async {
      var data = await api.allMaskedIds();
      var uType = data.map((e) => e['type']).toSet();
      expect(uType, {'participant', 'location', 'generator'});
    });
    test('get all available types', () async {
      var data = await api.getTypes();
      expect(data.toSet(), {'participant', 'location', 'generator'});
    });
    test('get one masked_participant_id', () async {
      var data = await api.getMaskedParticipantId(140603);
      expect(data, {
        'Masked Participant ID': 140603,
        'name': 'Exelon New England Holdings, L',
      });
      // get an unexisting participant
      var data2 = await api.getMaskedParticipantId(9);
      expect(data2.isEmpty, true);
    });
    test('try to get one unmasked participant id', () async {
      var url = [
        rootUrl,
        '/isone/masked_ids/v1/masked_asset_id/27008',
      ].join();
      var res = await http.get(Uri.parse(url));
      var data = json.decode(res.body);
      expect(data['ptid'], 555);
    });
    test('get one masked_location_id', () async {
      var data = await api.getMaskedLocationId(75309);
      expect(data, {
        'Masked Location ID': 75309,
        'ptid': 4000,
      });
    });
    test('get one masked_asset_id', () async {
      var data = await api.getMaskedAssetId(27008);
      expect(data['Masked Asset ID'], 27008);
      expect(data['ptid'], 555);
    });
  });

  group('ISO New England masked assets client tests:', () {
    var client = MaskedIds(http.Client(), iso: Iso.newEngland, rootUrl: rootUrl);
    test('get all masked generators', () async {
      var data = await client.getAssets(type: 'generator');
      var my9 = data.firstWhere((e) => e['ptid'] == 1616);
      expect(my9['name'], 'MYSTIC 9');
      expect(my9['Masked Asset ID'], 72020);
    });
    test('get all masked participants', () async {
      var data = await client.getAssets(type: 'participant');
      var nxt =
          data.firstWhere((e) => e['name'] == 'NextEra Energy Power Marketing');
      expect(nxt['Masked Participant ID'], 206845);
    });
    test('get all masked locations', () async {
      var data = await client.getAssets(type: 'location');
      var hub = data.firstWhere((e) => e['ptid'] == 4000);
      expect(hub['Masked Location ID'], 75309);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  DbProd();
  //dotenv.load('.env/test.env');
  var rootUrl = 'http://localhost:8080';
  await tests(rootUrl);
}
