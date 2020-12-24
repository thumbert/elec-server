library test.db.risk_system.calculator_archive_test;

import 'dart:convert';
import 'package:elec_server/api/risk_system/api_calculator.dart';
import 'package:elec_server/src/db/risk_system/calculator_archive.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'calculator_examples.dart';

void insertData(CalculatorArchive archive) async {
  var xs = [
    calc1(),
    calc2(),
    calc3(),
  ];
  for (var x in xs) {
    await archive.insertData(x);
  }
}

void tests(String rootUrl) async {
  var archive = CalculatorArchive();

  group('CalculatorArchive api tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    var api = ApiCalculators(archive.db);
    test('get users', () async {
      var res = await api.getUsers();
      expect(res, ['e11111', 'e42111']);
    });
    test('get all calculator types', () async {
      var res = await api.getCalculatorTypes();
      expect(res, ['elec_swap']);
    });
    test('get calculators, remove calculator, then add it back', () async {
      var _calcs = await api.calculatorsForUserId('e11111');
      expect(_calcs.length, 2);
      var calc = calc3();
      var res =
          await api.calculatorRemove(calc['userId'], calc['calculatorName']);
      var out = json.decode(res.result);
      expect(out['ok'], 1.0);
      var calcs = await api.calculatorsForUserId(calc['userId']);
      expect(calcs.length, 1);
      // add it back
      await archive.insertData(calc);
    });
  });
}

void repopulateDb() async {
  var archive = CalculatorArchive();
  await archive.db.open();
  // await archive.db.dropCollection('calculators');
  // await archive.dbConfig.coll.remove(<String, dynamic>{});
  await insertData(archive);
  // await archive.setup();
  await archive.db.close();
}

void main() async {
  await initializeTimeZones();
  // await repopulateDb();

  await tests('http://localhost:8080/');
}
