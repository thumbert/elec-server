import 'dart:convert';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/client/dalmp.dart' as client;
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/nyiso/da_lmp_hourly.dart';
import 'package:elec_server/api/api_lmp.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  group('Nyiso DAM LMP db tests: ', () {
    var archive = NyisoDaLmpHourlyArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('process DA hourly lmp report for 2019-01-01 (zones + gen nodes)',
        () async {
      var res = archive.processDay(Date.utc(2019, 1, 1));
      expect(res.length, 570); // both zones and gen nodes
      expect(res.first.keys.toSet(),
          {'date', 'ptid', 'lmp', 'congestion', 'losses'});
      expect(res.first['ptid'], 61757);
      expect(res.first['date'], '2019-01-01');
      expect(res.first['lmp'].take(3), [26.4, 22.97, 20.99]);
    });
  });
  group('Nyiso DAM LMP api tests: ', () {
    var api = Lmp(DbProd.nyiso, iso: Iso.newYork, market: Market.da);
    setUp(() async => await DbProd.nyiso.open());
    tearDown(() async => await DbProd.nyiso.close());
    test('get lmp data for 2 days', () async {
      var aux = await api.getHourlyData(
          61757, Date.utc(2019, 1, 1), Date.utc(2019, 1, 2), 'lmp');
      expect(aux.length, 2);
      expect(aux['2019-01-01']!.take(3), [26.4, 22.97, 20.99]);
      var url = '$rootUrl/nyiso/dalmp/v1/hourly/lmp/'
          'ptid/61757/start/2019-01-01/end/2019-01-02';
      var res = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as Map;
      expect(data.length, 2);
      expect(data['2019-01-01']!.take(3), [26.4, 22.97, 20.99]);
    });
    test('get daily lmp prices by peak bucket for one ptid', () async {
      var res = await http.get(
          Uri.parse('$rootUrl/nyiso/dalmp/v1/daily/lmp/'
              'ptid/61757/start/2019-01-01/end/2019-01-07/bucket/5x16'),
          headers: {'Content-Type': 'application/json'});
      var aux = json.decode(res.body) as List;
      expect(aux.length, 4);
      expect(aux.first, {'date': '2019-01-02', 'lmp': 36.040000000000006});
    });

    test('get daily lmp prices by peak bucket for two ptids', () async {
      var data = await api.getDailyBucketPriceSeveral('lmp', [61757, 61752],
          Date.utc(2019, 1, 1), Date.utc(2019, 1, 7), Bucket.b5x16);
      expect(data.length, 8);
      var n57 = data
          .firstWhere((e) => e['ptid'] == 61757 && e['date'] == '2019-01-02');
      expect(n57,
          {'ptid': 61757, 'date': '2019-01-02', 'lmp': 36.040000000000006});
      var res = await http.get(
          Uri.parse('$rootUrl/nyiso/dalmp/v1/daily/lmp/'
              'ptids/61757,61752/start/2019-01-01/end/2019-01-07/bucket/5x16'),
          headers: {'Content-Type': 'application/json'});
      var aux = json.decode(res.body) as List;
      expect(aux.length, 8);
      expect(
          aux.firstWhere(
              (e) => e['ptid'] == 61757 && e['date'] == '2019-01-02'),
          {'ptid': 61757, 'date': '2019-01-02', 'lmp': 36.040000000000006});
    });

    test('get daily lmp prices by flat bucket', () async {
      var data = await api.getDailyBucketPriceSeveral('lmp', [61757],
          Date.utc(2019, 1, 1), Date.utc(2019, 1, 7), Bucket.atc);
      expect(data[1]['lmp'], 32.415416666666665);
      expect(data.length, 7);
    });

    test('get daily 7x24 prices direct method (calculated by mongo)', () async {
      var data = await api.getDailyAtcPrices([61752, 61758],
          Date.utc(2019, 1, 1), Date.utc(2019, 12, 31), 'congestion');
      expect(data.first, {
        'date': '2019-01-01',
        'ptid': 61752,
        'congestion': -1.0204166666666667,
      });
      expect(data.length, 730);
      var url =
          '$rootUrl/nyiso/dalmp/v1/daily/congestion/ptids/61752,61758/start/2019-01-01/end/2019-12-31/bucket/7x24';
      var aux = await http.get(Uri.parse(url));
      var res = json.decode(aux.body) as List;
      expect(res.length, 730);
    });

    test('get monthly 7x24 prices direct method (calculated by mongo)',
        () async {
      var data = await api.getMonthlyAtcPrices([61752, 61758],
          Month.utc(2019, 1), Month.utc(2019, 12), 'congestion');
      expect(data.first, {
        'month': '2019-01',
        'ptid': 61752,
        'congestion': -4.766330645161291,
      });
      expect(data.length, 24);
    });

    test('get mean daily 7x24 prices all nodes 2019-01-01 (mongo)', () async {
      var data = await api.dailyPriceByPtid('lmp', '2019-01-01', '2019-01-01');
      var capitl = data.firstWhere((e) => e['ptid'] == 61757);
      expect((capitl['lmp'] as num).toStringAsFixed(4), '25.8650');
      expect(data.length, 570);
    });
    test('get monthly lmp prices by flat bucket', () async {
      var data = await api.getMonthlyBucketPrice(
          'lmp', 61757, '201901', '201902', 'flat');
      expect(data.length, 2);
      expect(data.first, {'month': '2019-01', 'lmp': 51.03111559139785});
    });
  });
  group('Nyiso DAM LMP speed tests: ', () {
    var api = Lmp(DbProd.nyiso, iso: Iso.newYork, market: Market.da);
    var sw = Stopwatch();
    setUp(() async => await DbProd.nyiso.open());
    tearDown(() async => await DbProd.nyiso.close());
    test('hourly lmp', () async {
      /// 43 ms for one ptid 365 days, 55 ms for 700 days.
      /// 28 ms just the db query to select one node for 365 days, 40 ms for 700 days.
      sw.start();
      var aux = await api.getHourlyData(
          61757, Date.utc(2019, 2, 14), Date.utc(2020, 1, 13), 'congestion');
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(100));
      expect(aux.containsKey('2019-02-14'), true);
    });
    test('get mean daily lmp prices all nodes 2017-01-01 (mongo)', () async {
      sw.reset();
      sw.start();
      var data = await api.dailyPriceByPtid('lmp', '2019-02-14', '2020-02-13');
      sw.stop();
      expect(
          sw.elapsedMilliseconds, lessThan(8000)); // was 3000 before 2024-08-02
      expect(data.length, 208891);
    });
  });

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
          IsoNewEngland.bucket5x16,
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

readDuckDb() {
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
