library test.db.isone.historical_btm_solar_test;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/isone/isone_btm_solar.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:http/http.dart' as http;
import 'package:elec/elec.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl) async {
  group('ISO New England BTM hourly solar DB tests:', () {
    final archive = getIsoneHistoricalBtmSolarArchive();
    test('read file 2023-10-13', () {
      var data = archive.processFile(Date.utc(2023, 10, 13));
      var x0 = data
          .firstWhere((e) => e['date'] == '2014-03-09' && e['zone'] == 'CT');
      expect((x0['values'] as List).length, 23);
      expect((x0['values'] as List)[6], 0.7);
      var x1 = data
          .firstWhere((e) => e['date'] == '2014-11-02' && e['zone'] == 'CT');
      expect((x1['values'] as List).length, 25);
      expect((x1['values'] as List)[7], 0.2);
    }, skip: true);
  });

  group('ISO New England BTM hourly solar API tests:', () {
    test('get all zones', () async {
      var res = await http.get(Uri.parse('$rootUrl/isone/btm/solar/v1/zones'));
      var data = json.decode(res.body) as List;
      expect(data.toSet(),
          {'CT', 'NEMA', 'SEMA', 'WCMA', 'ME', 'NH', 'RI', 'VT', 'ISONE'});
    });
    test('get data for one zone', () async {
      var res = await http.get(Uri.parse('$rootUrl/isone/btm/solar/v1/zone/CT/start/2022-04-01/end/2022-04-10'));
      var data = json.decode(res.body) as List;
      expect(data.length, 10); // one element per day
      expect((data.first as Map).keys.toSet(), {'date', 'values'});
      expect(data.first['date'], '2022-04-01');
      expect(data.first['values'][10], 200.9);
    });
  });

  group('ISO New England BTM hourly solar client tests:', () {
    var client = IsoneBtmSolar(rootUrl: rootUrl);
    test('get data for one zone', () async {
      var term = Term.parse('1Apr22-10Apr22', IsoNewEngland.location);
      var data = await client.getHourlyBtmForZone(term, zone: IsoNewEngland.connecticut);
      expect(data.length, 240);
      expect(data[10].value, 200.9);
    });
    test('get data for pool', () async {
      var term = Term.parse('1Apr22-10Apr22', IsoNewEngland.location);
      var data = await client.getHourlyBtmForPool(term);
      expect(data.length, 240);
      expect(data[10].value, 970.1);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await tests(dotenv.env['ROOT_URL']!);
}
