import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/isoexpress/fuelmix.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  group('FuelMix Report API tests:', () {
    setUp(() async => await DbProd.isoexpress.open());
    tearDown(() async => await DbProd.isoexpress.close());
    test('Get all fuel types', () async {
      var res = await http.get(Uri.parse('$rootUrl/isone/fuelmix/v1/types'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.length > 9, true);
      expect(data.contains('Natural Gas'), true);
    });

    test('Get mw for Natural Gas category', () async {
      var res = await http.get(
          Uri.parse(
              '$rootUrl/isone/fuelmix/v1/hourly/mw/type/Natural Gas/start/20200101/end/20200101'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.length, 1);
      expect((data.first as Map).keys.toSet(), {'date', 'mw'});
      expect(((data.first as Map)['mw'] as List).take(3),
          [3898.75, 3543.5, 3152.0]);
    });

    test('Get total generating mw across all fuel types', () async {
      var res = await http.get(
          Uri.parse(
              '$rootUrl/isone/fuelmix/v1/hourly/mw/type/all/start/20200101/end/20200102'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.length, 2);
      expect((data.first as Map).keys.toSet(), {'date', 'mw'});
      expect(((data.first as Map)['mw'] as List).take(3),
          [8753.833333333334, 8411.166666666666, 8070.75]);
    });
  });
  //
  //
  group('FuelMix Report API tests:', () {
    var client = FuelMix(http.Client(), rootUrl: rootUrl);
    test('get all fuel types', () async {
      var data = await client.getFuelTypes();
      expect(data.contains('Natural Gas'), true);
    });
    test('get hourly solar generation', () async {
      var term = Term.parse('1Jan20-2Jan20', IsoNewEngland.location);
      var data = await client.getHourlyMwForFuelType(term, fuelType: 'Solar');
      expect(data.length, 48);
      expect(data.values.toList()[8], 23.8);
    });
    test('get hourly total generation', () async {
      var term = Term.parse('1Jan20-2Jan20', IsoNewEngland.location);
      var data = await client.getHourlyMwForFuelType(term, fuelType: 'All');
      expect(data.length, 48);
      expect(data.values.toList()[2], 8070.75);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  DbProd();
  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
