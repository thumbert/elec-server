library test.api.utilities.api_load_eversource_test;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/api/utilities/api_load_eversource.dart';


tests() async {
  Db db;
  ApiLoadEversource api;
  setUp(() async {
    db = Db('mongodb://localhost/eversource');
    api = ApiLoadEversource(db);
    await db.open();
  });
  tearDown(() async {
    await db.close();
  });

  group('Eversource load test', () {
    test('CT load (CL&P)', () async {
      var data = await api.ctLoad('2014-01-01', '2014-01-01');
      var res = jsonDecode(data.result) as List;
      expect(res.length, 1);
      var e = res.first as Map<String,dynamic>;
      expect(e.keys.toList(), ['date', 'version', 'hourBeginning', 'load']);
      expect(e['hourBeginning'] is List, true);
      expect(e['hourBeginning'].first, '2014-01-01T00:00:00.000-0500');
    });
  });
}

main() async {
  await initializeTimeZone();
  await tests();
}