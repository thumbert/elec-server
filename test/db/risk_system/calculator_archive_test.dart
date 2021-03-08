library test.db.risk_system.calculator_archive_test;

import 'package:elec/calculators/elec_swap.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'dart:convert';
import 'package:elec_server/client/risk_system/calculator.dart';
import 'package:elec_server/src/db/risk_system/calculator_archive.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'calculator_examples.dart';

void insertData(CalculatorArchive archive) async {
  var xs = [
    calc1(),
    calc2(),
    calc3(),
    calcDo1(),
    calcDo2(),
  ];
  for (var x in xs) {
    await archive.insertData(x);
  }
}

void tests() async {
  var rootUrl = dotenv.env['SHELF_ROOT_URL'];
  var archive = CalculatorArchive();
  group('CalculatorArchive api tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('get all users', () async {
      var aux = await http.get('$rootUrl/calculators/v1/users',
          headers: {'Content-Type': 'application/json'});
      var res = json.decode(aux.body);
      expect(res, ['e11111', 'e42111']);
    });
    test('get calculator names for one user', () async {
      var aux = await http.get('$rootUrl/calculators/v1/user/e11111/names',
          headers: {'Content-Type': 'application/json'});
      var res = json.decode(aux.body) as List;
      expect(res.contains('custom monthly quantities, 1 leg'), true);
    });
    test('get all calculator types', () async {
      var aux = await http.get('$rootUrl/calculators/v1/calculator-types',
          headers: {'Content-Type': 'application/json'});
      var res = json.decode(aux.body) as List;
      expect(res.toSet(), {'elec_swap', 'elec_daily_option'});
    });
    test('get one calculator', () async {
      var url = '$rootUrl/calculators/v1/user/e11111/'
          'calculator-name/custom monthly quantities, 1 leg';
      var aux =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      var res = json.decode(aux.body);
      var calc = json.decode(res['result'] as String);
      expect(calc['userId'], 'e11111');
    });
    test('save a calculator, then delete it', () async {
      var calc = calc3();
      calc['calculatorName'] = 'test';
      var aux = await http.post(
        '$rootUrl/calculators/v1/save-calculator',
        headers: {'Content-Type': 'application/json'},
        body: json.encode(calc),
      );
      var res = json.decode(aux.body);
      expect(res['ok'], 1.0);
      // now delete it
      var url = '$rootUrl/calculators/v1/user/e11111/calculator-name/test';
      var aux2 =
          await http.delete(url, headers: {'Content-Type': 'application/json'});
      var res2 = json.decode(aux2.body);
      expect(res2['ok'], 1.0);
    });
  });
  group('CalculatorArchive client tests:', () {
    var client = CalculatorClient(http.Client(), rootUrl: rootUrl);
    test('save a calculator, then delete it', () async {
      var calc = calc3();
      calc['calculatorName'] = 'test2';
      var res = await client.saveCalculator(calc);
      expect(res['ok'], 1.0);
      var res2 =
          await client.deleteCalculator(calc['userId'], calc['calculatorName']);
      expect(res2['ok'], 1.0);
    });
    test('get a calculator one leg', () async {
      var calc = await client.getCalculator(
          'e11111', 'custom monthly quantities, 1 leg');
      expect(calc is ElecSwapCalculator, true);
    });
    // test('get a calculator 2 legs, saved from UI', () async {
    //   var calc = await client.getCalculator('e11111', 'test 1 2 3');
    //   expect(calc is ElecSwapCalculator, true);
    // });
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
  initializeTimeZones();
  // await repopulateDb();

  dotenv.load('.env/prod.env');
  tests();
}
