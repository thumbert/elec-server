library test.api.marks.curves.curve_id_test;

import 'dart:convert';

import 'package:elec_server/api/marks/curves/curve_ids.dart';
import 'package:elec_server/src/db/marks/curves/curve_id.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void tests() async {
  group('CurveIds api tests:', () {
    var archive = CurveIdArchive();
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    var api = CurveIds(archive.db);
    test('api get all curveIds', () async {
      var res = await api.curveIds();
      expect(res.length > 70, true);
    });
    test('api get all curveIds with pattern', () async {
      var res = await api.curveIdsWithPattern('opres_rt');
      expect(res.length, 8);
    });
    test('api get multiple curveIds', () async {
      var _ids = ['isone_energy_4000_da_lmp', 'isone_energy_4001_da_lmp']
        .join('|');
      var aux = await api.getCurveIds(_ids);
      var data = json.decode(aux.result) as List;
      expect(data.length, 2);
    });
  });
}

void main() async {
  await initializeTimeZones();
  await tests();
}
