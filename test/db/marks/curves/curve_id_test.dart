library test.db.curves.curve_id_test;

import 'dart:convert';

import 'package:elec_server/api/marks/curves/curve_ids.dart';
import 'package:elec_server/src/db/marks/curves/curve_id.dart';
import 'package:elec_server/src/db/marks/curves/curve_id/curve_id_isone.dart' as isone;
import 'package:test/test.dart';


void tests() async {
  group('CurveIds API', () {
    var archive = CurveIdArchive();
    var api = CurveIds(archive.db);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('get commodities', () async {
      var regions = await api.getCommodities();
      expect(regions.contains('electricity'), true);
    });
    test('get regions', () async {
      var regions = await api.getRegions('electricity');
      expect(regions.contains('isone'), true);
    });
    test('get serviceTypes', () async {
      var serviceTypes = await api.getServiceTypes('electricity', 'isone');
      expect(serviceTypes.toSet().containsAll({'arr', 'energy', 'fwdres', 'opres'}), true);
    });
    test('get electricity documents', () async {
      var aux = await api.getElectricityDocuments('isone', 'energy');
      var xs = json.decode(aux.result) as List;
      expect(xs.length >= 30, true);
    });

  });
}

void insertData() async {
  var archive = CurveIdArchive();
  await archive.db.open();
//  await archive.dbConfig.coll.remove(<String,dynamic>{});
  await archive.insertData(isone.getCurves());
  await archive.db.close();
}


void main() async {

//  await insertData();

  await tests();
}