library test.db.risk_system.calculator_archive_test;

import 'dart:convert';
import 'dart:math';
import 'package:elec/elec.dart';
import 'package:elec_server/api/risk_system/api_calculator.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/risk_system/calculator_archive.dart';
import 'package:test/test.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
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
  group('CalculatorArchive tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    // test('document equality', () {
    //   var document = <String, dynamic>{
    //     'fromDate': '2018-12-14',
    //     'version': '2018-12-14T10:12:47.000-0500',
    //     'curveId': 'isone_energy_4011_da_lmp',
    //     'markType': 'monthly',
    //     'terms': ['2019-01', '2019-02', '2019-12'],
    //     'buckets': {
    //       '5x16': [89.10, 86.25, 71.05],
    //       '2x16H': [72.19, 67.12, 42.67],
    //       '7x8': [44.18, 39.73, 38.56],
    //     }
    //   };
    //   var newDocument = <String, dynamic>{
    //     'fromDate': '2018-12-15',
    //     'version': '2018-12-15T11:15:47.000-0500',
    //     'curveId': 'isone_energy_4011_da_lmp',
    //     'markType': 'monthly',
    //     'terms': ['2019-01', '2019-02', '2019-12'],
    //     'buckets': {
    //       '5x16': [89.10, 86.25, 71.05],
    //       '2x16H': [72.19, 67.12, 42.67],
    //       '7x8': [44.18, 39.73, 38.56],
    //     }
    //   };
    //   expect(archive.needToInsert(document, newDocument), false);
    // });
  });

  group('CalculatorArchive api tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    var api = ApiCalculators(archive.db);
    test('api get all calculators for user e11111', () async {
      var res = await api.calculatorsForUserId('e11111');
      var calcs = json.decode(res.result) as List;
      expect(calcs.length, 2);
    });
    test('get all calculator types', () async {
      var res = await api.getCalculatorTypes();
      expect(res, ['elec_swap']);
    });
  });

  // group('ForwardMarks client tests:', () {
  //   var clientFm = client.ForwardMarks(Client(), rootUrl: rootUrl);
  //   var location = getLocation('America/New_York');
  //   test('get mh 5x16 as of 5/29/2020', () async {
  //     var curveId = 'isone_energy_4000_da_lmp';
  //     var mh5x16 = await clientFm.getMonthlyForwardCurveForBucket(
  //         curveId, Bucket.b5x16, Date(2020, 5, 29),
  //         tzLocation: location);
  //     expect(mh5x16.domain, Term.parse('Jun20-Dec26', location).interval);
  //   });
  //   test('get mh curve as of 5/29/2020 for all buckets', () async {
  //     var curveId = 'isone_energy_4000_da_lmp';
  //     var res = await clientFm.getMonthlyForwardCurve(
  //         curveId, Date(2020, 5, 29), tzLocation: location);
  //     expect(res.length, 79);
  //     var jan21 = res.observationAt(Month(2021, 1, location: location));
  //     expect(jan21.value[IsoNewEngland.bucket5x16], 58.25);
  //   });
  //   test('get mh hourly shape as of 5/29/2020 for all buckets', () async {
  //     var curveId = 'isone_energy_4000_hourlyshape';
  //     var hs = await clientFm.getHourlyShape(
  //         curveId, Date(2020, 5, 29), tzLocation: location);
  //     expect(hs.buckets.length, 3);
  //     expect(hs.data.first.interval.start.location.toString(),
  //         'America/New_York');
  //   });
  // });
}

void repopulateDb() async {
  var archive = CalculatorArchive();
  await archive.db.open();
  await archive.dbConfig.coll.remove(<String, dynamic>{});
  await insertData(archive);
  // await archive.setup();
  await archive.db.close();
}

void main() async {
  await initializeTimeZones();
  await repopulateDb();
//  await insertMarks();

  // await tests('http://localhost:8080/');
}
