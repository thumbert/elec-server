library test.db.curves.curve_id_test;

import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
//import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/api/marks/curves/curve_ids.dart';
import 'package:elec_server/src/db/marks/curves/curve_id.dart';
import 'package:elec_server/src/db/marks/curves/curve_id/curve_id_isone.dart'
    as isone;

void tests(String rootUrl) async {
  group('CurveIds API tests:', () {
    // var rootUrl = dotenv.env['SHELF_ROOT_URL'];
    var archive = CurveIdArchive();
    var api = CurveIds(archive.db);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('get all commodities', () async {
      var aux = await http.get(Uri.parse('$rootUrl/curve_ids/v1/commodities'),
          headers: {'Content-Type': 'application/json'});
      var res = json.decode(aux.body);
      expect(res.contains('electricity'), true);
    });
    test('get all regions for commodity electricity', () async {
      var aux = await http.get(Uri.parse(
          '$rootUrl/curve_ids/v1/commodity/electricity/regions'),
          headers: {'Content-Type': 'application/json'});
      var regions = json.decode(aux.body);
      expect(regions.contains('isone'), true);
    });
    test('get all serviceTypes for electricity, isone', () async {
      var serviceTypes = await api.getServiceTypes('electricity', 'isone');
      expect(
          serviceTypes
              .toSet()
              .containsAll({'arr', 'energy', 'fwdres', 'opres'}),
          true);
    });
    test('get energy curves for electricity, isone', () async {
      var aux = await http.get(Uri.parse(
          '$rootUrl/curve_ids/v1/data/commodity/electricity'
          '/region/isone/serviceType/energy'),
          headers: {'Content-Type': 'application/json'});
      var xs = json.decode(aux.body) as List;
      expect(xs.length >= 30, true);
    });
    test('get curve details for curveId isone_energy_4004_da_lmp', () async {
      var aux = await http.get(Uri.parse(
          '$rootUrl/curve_ids/v1/data/curveId/isone_energy_4004_da_lmp'),
          headers: {'Content-Type': 'application/json'});
      var xs = json.decode(aux.body);
      expect(xs['children'].toSet(), {
        'isone_energy_4000_da_lmp',
        'isone_energy_4004_da_basis',
      });
    });
    test('get curve details for curveId isone_energy_4000_da_lmp', () async {
      var aux = await http.get(Uri.parse(
          '$rootUrl/curve_ids/v1/data/curveId/isone_energy_4000_da_lmp'),
          headers: {'Content-Type': 'application/json'});
      var xs = json.decode(aux.body);
      expect(xs['volatilityCurveId'], {
        'daily': 'isone_volatility_4000_da_daily',
        'monthly': 'isone_volatility_4000_da_monthly',
      });
    });
    test('get curve details for two curveIds', () async {
      var curves = ['isone_energy_4000_da_lmp', 'isone_energy_4001_da_lmp'];
      var x = await api.getCurveIds(curves.join('|'));
      expect(x.length, 2);
      var aux = await http.get(Uri.parse(
          '$rootUrl/curve_ids/v1/data/curveIds/${curves.join('|')}'),
          headers: {'Content-Type': 'application/json'});
      var xs = json.decode(aux.body) as List;
      expect(xs.length, 2);
    });
    test('get mass hub daily volatility', () async {
      var aux = await http.get(Uri.parse(
          '$rootUrl/curve_ids/v1/data/curveId/isone_volatility_4000_da_daily'),
          headers: {'Content-Type': 'application/json'});
      var xs = json.decode(aux.body);
      expect(xs['commodity'], 'volatility');
      expect(xs['unit'], 'dimensionless');
      expect(xs['markType'], 'volatilitySurface');
    });
  });
}

void insertData() async {
  var archive = CurveIdArchive();
  await archive.db.open();
  await archive.dbConfig.coll.remove(<String, dynamic>{});
  await archive.insertData(isone.getCurves());
  await archive.setup();
  await archive.db.close();
}

void main() async {
  // await insertData();

  // dotenv.load('.env/prod.env');
  tests('http://127.0.0.1:8080');
}
