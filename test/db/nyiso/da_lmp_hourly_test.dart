import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/client/dalmp.dart' as client;
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
  group('Nyiso DAM LMP client tests: ', () {
    var daLmp = client.DaLmp(http.Client(), rootUrl: rootUrl);
    test('get daily peak price between two dates', () async {
      var data = await daLmp.getDailyLmpBucket(
          Iso.newYork,
          61752,
          LmpComponent.lmp,
          Bucket.b5x16,
          Date.utc(2019, 1, 1),
          Date.utc(2019, 1, 5));
      expect(data.length, 3);
      expect(data.toList(), [
        IntervalTuple(Date(2019, 1, 2, location: location), 31.678124999999998),
        IntervalTuple(Date(2019, 1, 3, location: location), 29.316875000000003),
        IntervalTuple(Date(2019, 1, 4, location: location), 23.630625000000002),
      ]);
    });
    test('get monthly peak price between two dates', () async {
      var data = await daLmp.getMonthlyLmpBucket(
          Iso.newYork,
          61752,
          LmpComponent.congestion,
          Bucket.b5x16,
          Month.utc(2019, 1),
          Month.utc(2019, 12));
      expect(data.length, 12);
      expect(
          data.first,
          IntervalTuple(
              Month(2019, 1, location: location), -7.513068181818175));
    });
    test('get hourly price for 2017-01-01', () async {
      var data = await daLmp.getHourlyLmp(Iso.newYork, 61752, LmpComponent.lmp,
          Date.utc(2019, 1, 1), Date.utc(2019, 1, 1));
      expect(data.length, 24);
      expect(
          data.first,
          IntervalTuple(
              Hour.beginning(TZDateTime(location, 2019, 1, 1)), 11.83));
    });
    test('get daily prices all nodes', () async {
      var data = await daLmp.getDailyPricesAllNodes(Iso.newYork,
          LmpComponent.lmp, Date.utc(2019, 1, 1), Date.utc(2019, 1, 3));
      expect(data.length, 570);
      var zA = data[61752]!;
      expect(zA.first.value, 17.090833333333332);
    });
  });
}

// Future speedTest(String rootUrl) async {
//   var location = getLocation('America/New_York');
//   var daLmp = client.DaLmp(http.Client(), rootUrl: rootUrl);
//
//   var data = await daLmp.getHourlyLmp(
//       4000, LmpComponent.lmp, Date.utc(2017, 1, 1), Date.utc(2017, 1, 1));
// }

void readDuckDb() {
  final conn =
      Connection('/home/adrian/Downloads/Archive/DuckDB/nyiso/dalmp.duckdb');
  final result = conn.fetch('SELECT * FROM dalmp WHERE ptid = 61752 '
      'and hour_beginning >= \'2024-11-03\' and hour_beginning < \'2024-11-04\'');
  print(result); // not working
}

void main() async {
  initializeTimeZones();
  readDuckDb();

  // DbProd();
  // // dotenv.load('.env/prod.env');
  // tests('http://127.0.0.1:8080');
}
