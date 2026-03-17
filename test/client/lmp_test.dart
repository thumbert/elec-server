import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:elec_server/client/lmp.dart';
import 'package:test/test.dart';

import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');

  group('LMP client tests ISONE: ', () {
    test('get hourly lmp prices ISONE', () async {
      var data = await IsoNewEngland().getHourlyLmp(
          ptid: 4000,
          component: LmpComponent.lmp,
          term: Term(Date.utc(2025, 1, 1), Date.utc(2025, 1, 1)),
          market: Market.da,
          rustServer: rootUrl);
      expect(data.length, 24);
      expect(data.take(3).toList(), [
        IntervalTuple<num>(
            Hour.beginning(TZDateTime(location, 2025, 1, 1, 0)), 37.21),
        IntervalTuple<num>(
            Hour.beginning(TZDateTime(location, 2025, 1, 1, 1)), 35.09),
        IntervalTuple<num>(
            Hour.beginning(TZDateTime(location, 2025, 1, 1, 2)), 31.62),
      ]);
    });

    test('get hourly congestion prices ISONE', () async {
      var data = await IsoNewEngland().getHourlyLmp(
          ptid: 4000,
          component: LmpComponent.congestion,
          term: Term(Date.utc(2025, 1, 1), Date.utc(2025, 1, 1)),
          market: Market.da,
          rustServer: rootUrl);
      expect(data.length, 24);
      expect(data.take(3).toList(), [
        IntervalTuple<num>(
            Hour.beginning(TZDateTime(location, 2025, 1, 1, 0)), 0.0),
        IntervalTuple<num>(
            Hour.beginning(TZDateTime(location, 2025, 1, 1, 1)), 0.0),
        IntervalTuple<num>(
            Hour.beginning(TZDateTime(location, 2025, 1, 1, 2)), 0.0),
      ]);
    });

    test('get daily lmp prices ISONE', () async {
      var data = await IsoNewEngland().getDailyLmp(
          ptid: 4000,
          component: LmpComponent.lmp,
          term: Term.parse('Jan26', IsoNewEngland.location),
          market: Market.da,
          bucket: Bucket.offpeak,
          rustServer: rootUrl);
      expect(data.length, 31);
      expect(data.take(3).toList(), [
        IntervalTuple<num>(
            Date(2026, 1, 1, location: IsoNewEngland.location), 157.0921),
        IntervalTuple<num>(
            Date(2026, 1, 2, location: IsoNewEngland.location), 168.825),
        IntervalTuple<num>(
            Date(2026, 1, 3, location: IsoNewEngland.location), 154.7633),
      ]);
    });

    test('get monthly lmp prices ISONE', () async {
      var data = await IsoNewEngland().getMonthlyLmp(
          ptid: 4000,
          component: LmpComponent.lmp,
          term: Term.parse('Jan26-Feb26', IsoNewEngland.location),
          market: Market.da,
          bucket: Bucket.offpeak,
          rustServer: rootUrl);
      expect(data.length, 2);
      expect(data, [
        IntervalTuple<num>(
            Month(2026, 1, location: IsoNewEngland.location), 173.0978),
        IntervalTuple<num>(
            Month(2026, 2, location: IsoNewEngland.location), 122.527),
      ]);
    });

    test('get monthly lmp prices CAISO', () async {
      var data = await Caiso().getMonthlyLmp(
          locationName: 'TH_NP15_GEN-APND',
          component: LmpComponent.lmp,
          term: Term.parse('Jan26-Feb26', Caiso.location),
          market: Market.da,
          bucket: Caiso.bucket6x16,
          rustServer: rootUrl);
      expect(data.length, 2);
      expect(data, [
        IntervalTuple<num>(Month(2026, 1, location: Caiso.location), 34.07972),
        IntervalTuple<num>(Month(2026, 2, location: Caiso.location), 29.00402),
      ]);
    });
  });
}

Future<void> getCaisoPrices() async {
  var location = getLocation('America/Los_Angeles');
  var term = Term.parse('Jan26', location);
  var np15 = await Caiso().getHourlyLmp(
      locationName: 'TH_NP15_GEN-APND',
      component: LmpComponent.lmp,
      term: term,
      market: Market.da,
      rustServer: dotenv.env['RUST_SERVER']!);
  var sp15 = await Caiso().getHourlyLmp(
      locationName: 'TH_SP15_GEN-APND',
      component: LmpComponent.lmp,
      term: term,
      market: Market.da,
      rustServer: dotenv.env['RUST_SERVER']!);
  var out = '''
final prices = <Map<String, dynamic>>[
  {
    'x': [${np15.map((e) => "'${e.interval.start.toIso8601String()}'").toList().join(',')}],
    'y': [${np15.map((e) => e.value).toList().join(',')}],
    'name': 'TH_NP15_GEN-APND',
  },
  {
    'x': [${sp15.map((e) => "'${e.interval.start.toIso8601String()}'").toList().join(',')}],
    'y': [${sp15.map((e) => e.value).toList().join(',')}],
    'name': 'TH_SP15_GEN-APND',
  },
];
''';
  File('/home/adrian/Downloads/caiso_prices.dart').writeAsStringSync(out);
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await tests(dotenv.env['RUST_SERVER']!);
  // await getCaisoPrices();
}
