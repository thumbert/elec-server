library test.client.marks.curves.curve_id_test;

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/marks/curves/curve_id.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void tests() async {
  var shelfRootUrl = dotenv.env['SHELF_ROOT_URL'];
  group('CurveIds client tests:', () {
    var client = CurveIdClient(Client(), rootUrl: shelfRootUrl);
    test('get all curveIds', () async {
      var ids = await client.curveIds();
      expect(ids.length > 5, true);
    });
    test('get all curveIds, with a given pattern', () async {
      var ids = await client.curveIds(pattern: 'opres_rt');
      expect(ids.length, 8);
    });
    test('get data for one curveId', () async {
      var xs = await client.getCurveId('isone_energy_4000_da_lmp');
      expect(xs.keys.length > 11, true);
    });
    test('get data for several curveIds', () async {
      var xs = await client.getCurveIds([
        'isone_energy_4000_da_lmp',
        'isone_energy_4001_da_lmp',
      ]);
      expect(xs.length, 2);
    });
    test('get all commodities', () async {
      var commods = await client.commodities();
      expect(commods.contains('electricity'), true);
    });
    test('get all regions', () async {
      var regions = await client.regions('electricity');
      expect(regions.contains('isone'), true);
    });
    test('get all serviceTypes', () async {
      var types = await client.serviceTypes('electricity', 'isone');
      expect(types.toSet().containsAll({'energy', 'arr', 'fwdres', 'opres'}),
          true);
    });
    test('get all electricity documents', () async {
      var xs = await client.electricityDocuments('isone', 'opres');
      expect(xs.length, 9); // 8 opres rt zones + 1 opres da pool
    });
  });
}

void main() async {
  initializeTimeZones();

  dotenv.load('.env/prod.env');
  tests();
}
