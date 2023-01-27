library test.db.isoexpress.da_lmp_hourly_test;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/api/api_dalmp.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/client/dalmp.dart' as client;
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:dotenv/dotenv.dart' as dotenv;


/// prepare data by downloading a few reports
/// Missing 9/29/2018 and 9/30/2018 !!!
Future<void> prepareData() async {
  var archive = DaLmpHourlyArchive();
  var days = [
    Date.utc(2018, 9, 26),
    Date.utc(2018, 9, 29),
    Date.utc(2018, 9, 30),
    Date.utc(2022, 12, 22), // switched to json
  ];
  await archive.downloadDays(days);
}

Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  group('ISONE DAM LMP db tests: ', () {
    var archive = DaLmpHourlyArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read dam file, 2022-12-22 json format', () {
      var file = archive.getFilename(Date.utc(2022, 12, 22));
      var res = archive.processFile(file);
      expect(res.first.keys.toSet(),
          {'date', 'ptid', 'lmp', 'congestion', 'marginal_loss'});
      var p321 = res.firstWhere((e) => e['ptid'] == 321);
      expect(p321['lmp'].first, 96.86);
    });
    test('process DA hourly lmp report, 2019-05-09', () {
      /// has duplicated data for ptid: 38206
      var file = archive.getFilename(Date.utc(2019, 5, 9));
      var res = archive.processFile(file);
      var p38206 = res.firstWhere((e) => e['ptid'] == 38206);
      expect(p38206['lmp'].length, 24);
    });
    test('DA hourly lmp report, DST day spring', () {
      var file = archive.getFilename(Date.utc(2017, 3, 12));
      var res = archive.processFile(file);
      expect(res.first['lmp'].length, 23);
    });
    test('DA hourly lmp report, DST day fall', () async {
      var file = archive.getFilename(Date.utc(2017, 11, 5));
      var res = archive.processFile(file);
      expect(res.first['lmp'].length, 25);
    });
    test('Insert one day', () async {
      var date = Date.utc(2017, 1, 1);
      if (!await archive.hasDay(date)) await archive.insertDay(date);
    });
    test('insert several days', () async {
      var days = Interval(TZDateTime(location, 2017, 1, 1),
              TZDateTime(location, 2017, 1, 5))
          .splitLeft((dt) => Date.utc(dt.year, dt.month, dt.day));
      await for (var day in Stream.fromIterable(days)) {
        if (!await archive.hasDay(day)) {
          await archive.downloadDay(day);
          await archive.insertDay(day);
        }
      }
    });
    test('hasDay', () async {
      var d1 = Date.utc(2017, 1, 1);
      var res = await archive.hasDay(d1);
      expect(res, true);
      var d2 = Date.today(location: UTC).next.next;
      res = await archive.hasDay(d2);
      expect(res, false);
    });
  });
  group('DAM LMP api tests: ', () {
    var db = DbProd.isoexpress;
    var api = DaLmp(db, iso: Iso.newEngland);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get hourly lmp data for 2 days', () async {
      var aux = await api.getHourlyData(
          4000, Date.utc(2017, 1, 1), Date.utc(2017, 1, 2), 'lmp');
      expect(aux.length, 2);
      expect((aux['2017-01-01'] as List).first, 35.12);
      var url = '$rootUrl/dalmp/v1/hourly/lmp/'
          'ptid/4000/start/2017-01-01/end/2017-01-02';
      var res = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as Map;
      expect(data.length, 2);
      expect((data['2017-01-01'] as List).first, 35.12);
    });

    test('get hourly lmp data for several ptids for several days', () async {
      var url = '$rootUrl/isone/da/v1/hourly/lmp/'
          'ptids/4000,4001/start/2017-01-01/end/2017-01-02';
      var res = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.length, 2*48);
      var x0 = data.firstWhere((e) => e['ptid'] == 4000);
      expect(x0, {
        'hourBeginning': '2017-01-01T00:00:00.000-0500',
        'ptid': 4000,
        'lmp': 35.12,
      });
    });


    // test('get lmp data for 2 days (compact)', () async {
    //   var aux = await api.getHourlyPricesCompact(
    //       'lmp', 4000, '2017-01-01', '2017-01-02');
    //   expect(aux.length, 48);
    //   expect(aux.first, 35.12);
    // });

    test('get daily lmp prices by peak bucket', () async {
      var res = await http.get(
          Uri.parse('$rootUrl/dalmp/v1/daily/lmp/'
              'ptid/4000/start/2017-07-01/end/2017-07-07/bucket/5x16'),
          headers: {'Content-Type': 'application/json'});
      var aux = json.decode(res.body) as List;
      expect(aux.length, 4);
      expect(aux.first, {'date': '2017-07-03', 'lmp': 35.225});
    });

    test('get daily lmp prices by flat bucket', () async {
      var data = await api.getDailyBucketPriceSeveral('lmp', [4000],
          Date.utc(2017, 1, 1), Date.utc(2017, 1, 2), Bucket.atc);
      expect(data[0]['lmp'], 37.86666666666667);
      expect(data.length, 2);
    });

    test('get mean daily lmp prices all nodes 2017-01-01 (mongo)', () async {
      var data = await api.dailyPriceByPtid('lmp', '2017-07-03', '2017-07-03');
      var hub = data.firstWhere((e) => e['ptid'] == 4000);
      expect((hub['lmp'] as num).toStringAsFixed(4), '30.2825');
      expect(data.length, 1142);
    });

    test('get monthly lmp prices by flat bucket', () async {
      var data = await api.getMonthlyBucketPrice(
          'lmp', 4000, '201707', '201708', 'flat');
      expect(data.length, 2);
      expect(data.first, {'month': '2017-07', 'lmp': 27.60442204301075});
    });
  });
  group('DAM LMP client tests: ', () {
    var daLmp =
        client.DaLmp(http.Client(), iso: Iso.newEngland, rootUrl: rootUrl);
    test('get daily peak price between two dates', () async {
      var data = await daLmp.getDailyLmpBucket(4000, LmpComponent.lmp,
          IsoNewEngland.bucket5x16, Date.utc(2017, 1, 1), Date.utc(2017, 1, 5));
      expect(data.length, 3);
      expect(data.toList(), [
        IntervalTuple(Date(2017, 1, 3, location: location), 45.64124999999999),
        IntervalTuple(Date(2017, 1, 4, location: location), 39.103125),
        IntervalTuple(Date(2017, 1, 5, location: location), 56.458749999999995)
      ]);
    });
    test('get monthly peak price between two dates', () async {
      var data = await daLmp.getMonthlyLmpBucket(4000, LmpComponent.lmp,
          IsoNewEngland.bucket5x16, Month.utc(2017, 1), Month.utc(2017, 8));
      expect(data.length, 8);
      expect(data.first,
          IntervalTuple(Month(2017, 1, location: location), 42.55883928571426));
    });
    test('get hourly price for 2017-01-01', () async {
      var data = await daLmp.getHourlyLmp(
          4000, LmpComponent.lmp, Date.utc(2017, 1, 1), Date.utc(2017, 1, 1));
      expect(data.length, 24);
      expect(
          data.first,
          IntervalTuple(
              Hour.beginning(TZDateTime(location, 2017, 1, 1)), 35.12));
    });
    test('get daily prices all nodes', () async {
      var data = await daLmp.getDailyPricesAllNodes(
          LmpComponent.lmp, Date.utc(2017, 1, 1), Date.utc(2017, 1, 3));
      expect(data.length, 1136);
      var p321 = data[321]!;
      expect(p321.first.value, 37.755);
    });
  });
}

Future<void> speedTest(String rootUrl) async {
  var location = getLocation('America/New_York');
  var daLmp =
      client.DaLmp(http.Client(), iso: Iso.newEngland, rootUrl: rootUrl);

  var data = await daLmp.getHourlyLmp(
      4000, LmpComponent.lmp, Date.utc(2017, 1, 1), Date.utc(2017, 1, 1));
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  // await DaLmpHourlyArchive().setupDb();
  // await prepareData();

  DbProd();
  tests('http://127.0.0.1:8080');


  // await soloTest();
}
