import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/lmp.dart' as client;
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');

  group('LMP client tests: ', () {
    var lmp = client.Lmp(http.Client(), rustServer: rootUrl);
    test('get hourly lmp prices ISONE', () async {
      var data = await lmp.getHourlyLmp(
          iso: Iso.newEngland,
          ptid: 4000,
          component: LmpComponent.lmp,
          term: Term(Date.utc(2025, 1, 1), Date.utc(2025, 1, 1)),
          market: Market.da);
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
      var data = await lmp.getHourlyLmp(
          iso: Iso.newEngland,
          ptid: 4000,
          component: LmpComponent.congestion,
          term: Term(Date.utc(2025, 1, 1), Date.utc(2025, 1, 1)),
          market: Market.da);
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
    
  });
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['RUST_SERVER']!;
  await tests(rootUrl);
}
