library test.db.isoexpress.da_lmp_hourly_test;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
//import 'package:dotenv/dotenv.dart' as dotenv;

import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/api/isoexpress/api_isone_dalmp.dart';
import 'package:elec_server/client/isoexpress/dalmp.dart' as client;
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';

/// prepare data by downloading a few reports
/// Missing 9/29/2018 and 9/30/2018 !!!
void prepareData() async {
  var archive = DaLmpHourlyArchive();
  var days = [
    Date(2018, 9, 26),
    Date(2018, 9, 29),
    Date(2018, 9, 30),
  ];
  await archive.downloadDays(days);
}

void tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  // var rootUrl = dotenv.env['SHELF_ROOT_URL'];
  group('DAM LMP db tests: ', () {
    var archive = DaLmpHourlyArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('DA hourly lmp report, DST day spring', () {
      var file = archive.getFilename(Date(2017, 3, 12));
      var res = archive.processFile(file);
      expect(res.first['hourBeginning'].length, 23);
    });
    test('DA hourly lmp report, DST day fall', () async {
      var file = archive.getFilename(Date(2017, 11, 5));
      var res = archive.processFile(file);
      expect(res.first['hourBeginning'].length, 25);
    });
    test('Insert one day', () async {
      var date = Date(2017, 1, 1);
      if (!await archive.hasDay(date)) await archive.insertDay(date);
    });
    test('insert several days', () async {
      var days = Interval(TZDateTime(location, 2017, 1, 1),
              TZDateTime(location, 2017, 1, 5))
          .splitLeft((dt) => Date(dt.year, dt.month, dt.day));
      await for (var day in Stream.fromIterable(days)) {
        if (!await archive.hasDay(day)) {
          await archive.downloadDay(day);
          await archive.insertDay(day);
        }
      }
    });
    test('hasDay', () async {
      var d1 = Date(2017, 1, 1);
      var res = await archive.hasDay(d1);
      expect(res, true);
      var d2 = Date.today().next.next;
      res = await archive.hasDay(d2);
      expect(res, false);
    });
  });
  group('DAM LMP api tests: ', () {
    var db = DbProd.isoexpress;
    var api = DaLmp(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get lmp data for 2 days', () async {
      var aux = await api.getHourlyData(
          4000, Date(2017, 1, 1), Date(2017, 1, 2), 'lmp');
      expect(aux.length, 48);
      expect(aux.first, {
        'hourBeginning': '2017-01-01 00:00:00.000-0500',
        'lmp': 35.12,
      });
      var res = await http.get(Uri.parse(
          '$rootUrl/dalmp/v1/hourly/lmp/'
          'ptid/4000/start/2017-01-01/end/2017-01-02'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.length, 48);
      expect(data.first, {
        'hourBeginning': '2017-01-01 00:00:00.000-0500',
        'lmp': 35.12,
      });
    });
    test('get lmp data for 2 days (compact)', () async {
      var aux = await api.getHourlyPricesCompact(
          'lmp', 4000, '2017-01-01', '2017-01-02');
      expect(aux.length, 48);
      expect(aux.first, 35.12);
    });

    test('get daily lmp prices by peak bucket', () async {
      var data = await api.getDailyBucketPrice(
          'lmp', 4000, '2017-07-01', '2017-07-07', '5x16');
      expect(data.length, 4);
      expect(data.first, {'date': '2017-07-03', 'lmp': 35.225});
      var res = await http.get(Uri.parse(
          '$rootUrl/dalmp/v1/daily/lmp/'
          'ptid/4000/start/2017-07-01/end/2017-07-07/bucket/5x16'),
          headers: {'Content-Type': 'application/json'});
      var aux = json.decode(res.body) as List;
      expect(aux.length, 4);
      expect(aux.first, {'date': '2017-07-03', 'lmp': 35.225});
    });

    test('get daily lmp prices by flat bucket', () async {
      var data = await api.getDailyBucketPrice(
          'lmp', 4000, '2017-07-01', '2017-07-07', 'flat');
      expect(data[2]['lmp'], 30.2825);
      expect(data.length, 7);
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
      expect(data.first, {'month': '2017-07', 'lmp': 27.604422043010757});
    });
  });
  group('DAM LMP client tests: ', () {
    var daLmp = client.DaLmp(http.Client(), rootUrl: rootUrl);
    test('get daily peak price between two dates', () async {
      var data = await daLmp.getDailyLmpBucket(4000, LmpComponent.lmp,
          IsoNewEngland.bucket5x16, Date(2017, 1, 1), Date(2017, 1, 5));
      expect(data.length, 3);
      expect(data.toList(), [
        IntervalTuple(Date(2017, 1, 3, location: location), 45.64124999999999),
        IntervalTuple(Date(2017, 1, 4, location: location), 39.103125),
        IntervalTuple(Date(2017, 1, 5, location: location), 56.458749999999995)
      ]);
    });

    test('get monthly peak price between two dates', () async {
      var data = await daLmp.getMonthlyLmpBucket(4000, LmpComponent.lmp,
          IsoNewEngland.bucket5x16, Month(2017, 1), Month(2017, 8));
      expect(data.length, 8);
      expect(data.first,
          IntervalTuple(Month(2017, 1, location: location), 42.55883928571426));
    });

    test('get hourly price for 2017-01-01', () async {
      var data = await daLmp.getHourlyLmp(
          4000, LmpComponent.lmp, Date(2017, 1, 1), Date(2017, 1, 1));
      expect(data.length, 24);
      expect(
          data.first,
          IntervalTuple(
              Hour.beginning(TZDateTime(location, 2017, 1, 1)), 35.12));
    });

    test('get daily prices all nodes', () async {
      var data = await daLmp.getDailyPricesAllNodes(
          LmpComponent.lmp, Date(2017, 1, 1), Date(2017, 1, 3));
      expect(data.length, 1136);
      var p321 = data[321];
      expect(p321.first.value, 37.755);
    });
  });
}

Future soloTest() async {
  var archive = DaLmpHourlyArchive();
//  await archive.setupDb();
  var location = getLocation('America/New_York');
  var days = Interval(
          TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2017, 9, 1))
      .splitLeft((dt) => Date.fromTZDateTime(dt));
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

void main() async {
  initializeTimeZones();
  // await DaLmpHourlyArchive().setupDb();
  // await prepareData();

  DbProd();
  // dotenv.load('.env/prod.env');
  tests('http://127.0.0.1:8080');

//  Db db = new Db('mongodb://localhost/isoexpress');
//  await new DaLmpHourlyArchive().updateDb(new DaLmp(db));

  // await soloTest();
}
