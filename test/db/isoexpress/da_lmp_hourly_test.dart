import 'dart:async';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/dalmp.dart' as client;
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');

  group('DAM LMP client tests for ISONE: ', () {
    var daLmp = client.DaLmp(http.Client(), rootUrl: rootUrl);
    test('get daily peak price between two dates', () async {
      var data = await daLmp.getDailyLmpBucket(
          Iso.newEngland,
          4000,
          LmpComponent.lmp,
          IsoNewEngland.bucket5x16,
          Date.utc(2025, 1, 1),
          Date.utc(2025, 1, 5));
      expect(data.toList(), [
        IntervalTuple<num>(Date(2025, 1, 2, location: location), 61.6119),
        IntervalTuple<num>(Date(2025, 1, 3, location: location), 79.1681),
      ]);
    });
    test('get monthly peak price between two dates', () async {
      var data = await daLmp.getMonthlyLmpBucket(
          Iso.newEngland,
          4000,
          LmpComponent.lmp,
          IsoNewEngland.bucket5x16,
          Month.utc(2025, 1),
          Month.utc(2025, 8));
      expect(data.first,
          IntervalTuple<num>(Month(2025, 1, location: location), 147.4221));
    });

    test('get hourly prices for 4000', () async {
      var data = await daLmp.getHourlyLmp(Iso.newEngland, 4000,
          LmpComponent.lmp, Date.utc(2025, 1, 1), Date.utc(2025, 1, 2));
      expect(data.length, 48);
      expect(
          data.first,
          IntervalTuple<num>(
              Hour.beginning(TZDateTime(location, 2025, 1, 1)), 37.21));
    });
    test('get daily prices all nodes', () async {
      var data = await daLmp.getDailyPricesAllNodes(Iso.newEngland,
          LmpComponent.lmp, Date.utc(2025, 1, 1), Date.utc(2025, 1, 3));
      expect(data.length, 1213);
      var p321 = data[321]!;
      expect(p321.first.value, 38.3763);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  DbProd();
  tests(dotenv.env['RUST_SERVER']!);
}
