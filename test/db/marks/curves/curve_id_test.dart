library test.db.curves.curve_id_test;

import 'package:elec_server/api/marks/curves/curve_ids.dart';
import 'package:elec_server/src/db/marks/curves/curve_id.dart';
import 'package:elec_server/src/db/marks/curves/json/curve_id_isone.dart' as isone;
import 'package:test/test.dart';


void tests() async {
  group('CurveIds API', () {
    var archive = CurveIdArchive();
    var api = CurveIds(archive.db);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('get regions', () async {
      var regions = await api.getRegions();
      print(regions);
      expect(regions.contains('isone'), true);
    });
  });
}

void insertData() async {
  var archive = CurveIdArchive();
  await archive.db.open();
  await archive.insertData(isone.getCurves());
  await archive.db.close();
}


void main() async {
//  await insertData();

  await tests();
}