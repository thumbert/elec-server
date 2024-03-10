library test.db.isoexpress.da_lmp_hourly_test;

import 'dart:async';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';

import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  group('ISONE Rt System Load 5 min tests:', () {
    var archive = getRtSystemLoad5minArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read file for 2021-08-01', () {
      var file = archive.getFilename(Date.utc(2021, 8, 1));
      expect(
          file.path, '${archive.dir}isone_systemload_5min_2021-08-01.json.gz');
      var res = archive.processFile(file);
      expect(res.length, 1);
      expect(res.first.keys.toSet(), {
        'date',
        'minuteOffset',
        'load',
        'nativeLoad',
        'ardDemand',
        'systemLoadBtmPv',
        'nativeLoadBtmPv'
      });
      expect((res.first['load'] as List).length, 288); // 24 * 12
      expect((res.first['minuteStart'] as List).take(3), [
        0,
        5,
        10,
      ]);
      expect((res.first['load'] as List).take(3), [
        10867.729,
        10835.519,
        10742.174,
      ]);
    });
  });

  // group('DAM LMP api tests: ', () {
  // var db = DbProd.isoexpress;
  // var api = Lmp(db, iso: Iso.newEngland, market: Market.da);
  // setUp(() async => await db.open());
  // tearDown(() async => await db.close());
  // test('get hourly lmp data for 2 days', () async {
  //   var aux = await api.getHourlyData(
  //       4000, Date.utc(2017, 1, 1), Date.utc(2017, 1, 2), 'lmp');
  //   expect(aux.length, 2);
  //   expect((aux['2017-01-01'] as List).first, 35.12);
  //   var url = '$rootUrl/dalmp/v1/hourly/lmp/'
  //       'ptid/4000/start/2017-01-01/end/2017-01-02';
  //   var res = await http
  //       .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
  //   var data = json.decode(res.body) as Map;
  //   expect(data.length, 2);
  //   expect((data['2017-01-01'] as List).first, 35.12);
  // });

  // test('get hourly lmp data for several ptids for several days', () async {
  //   var url = '$rootUrl/isone/da/v1/hourly/lmp/'
  //       'ptids/4000,4001/start/2017-01-01/end/2017-01-02';
  //   var res = await http
  //       .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
  //   var data = json.decode(res.body) as List;
  //   expect(data.length, 2*48);
  //   var x0 = data.firstWhere((e) => e['ptid'] == 4000);
  //   expect(x0, {
  //     'hourBeginning': '2017-01-01T00:00:00.000-0500',
  //     'ptid': 4000,
  //     'lmp': 35.12,
  //   });
  // });

  // test('get lmp data for 2 days (compact)', () async {
  //   var aux = await api.getHourlyPricesCompact(
  //       'lmp', 4000, '2017-01-01', '2017-01-02');
  //   expect(aux.length, 48);
  //   expect(aux.first, 35.12);
  // });

  //   test('get daily lmp prices by peak bucket', () async {
  //     var res = await http.get(
  //         Uri.parse('$rootUrl/dalmp/v1/daily/lmp/'
  //             'ptid/4000/start/2017-07-01/end/2017-07-07/bucket/5x16'),
  //         headers: {'Content-Type': 'application/json'});
  //     var aux = json.decode(res.body) as List;
  //     expect(aux.length, 4);
  //     expect(aux.first, {'date': '2017-07-03', 'lmp': 35.225});
  //   });

  //   test('get daily lmp prices by flat bucket', () async {
  //     var data = await api.getDailyBucketPriceSeveral('lmp', [4000],
  //         Date.utc(2017, 1, 1), Date.utc(2017, 1, 2), Bucket.atc);
  //     expect(data[0]['lmp'], 37.86666666666667);
  //     expect(data.length, 2);
  //   });

  //   test('get mean daily lmp prices all nodes 2017-01-01 (mongo)', () async {
  //     var data = await api.dailyPriceByPtid('lmp', '2017-07-03', '2017-07-03');
  //     var hub = data.firstWhere((e) => e['ptid'] == 4000);
  //     expect((hub['lmp'] as num).toStringAsFixed(4), '30.2825');
  //     expect(data.length, 1142);
  //   });

  //   test('get monthly lmp prices by flat bucket', () async {
  //     var data = await api.getMonthlyBucketPrice(
  //         'lmp', 4000, '201707', '201708', 'flat');
  //     expect(data.length, 2);
  //     expect(data.first, {'month': '2017-07', 'lmp': 27.60442204301075});
  //   });
  // });
  // group('DAM LMP client tests: ', () {
  //   var daLmp = client.DaLmp(http.Client(), rootUrl: rootUrl);
  //   test('get daily peak price between two dates', () async {
  //     var data = await daLmp.getDailyLmpBucket(Iso.newEngland, 4000, LmpComponent.lmp,
  //         IsoNewEngland.bucket5x16, Date.utc(2017, 1, 1), Date.utc(2017, 1, 5));
  //     expect(data.length, 3);
  //     expect(data.toList(), [
  //       IntervalTuple(Date(2017, 1, 3, location: location), 45.64124999999999),
  //       IntervalTuple(Date(2017, 1, 4, location: location), 39.103125),
  //       IntervalTuple(Date(2017, 1, 5, location: location), 56.458749999999995)
  //     ]);
  //   });
  //   test('get monthly peak price between two dates', () async {
  //     var data = await daLmp.getMonthlyLmpBucket(Iso.newEngland,4000, LmpComponent.lmp,
  //         IsoNewEngland.bucket5x16, Month.utc(2017, 1), Month.utc(2017, 8));
  //     expect(data.length, 8);
  //     expect(data.first,
  //         IntervalTuple(Month(2017, 1, location: location), 42.55883928571426));
  //   });
  //   test('get hourly price for 2017-01-01', () async {
  //     var data = await daLmp.getHourlyLmp(Iso.newEngland,
  //         4000, LmpComponent.lmp, Date.utc(2017, 1, 1), Date.utc(2017, 1, 1));
  //     expect(data.length, 24);
  //     expect(
  //         data.first,
  //         IntervalTuple(
  //             Hour.beginning(TZDateTime(location, 2017, 1, 1)), 35.12));
  //   });
  //   test('get daily prices all nodes', () async {
  //     var data = await daLmp.getDailyPricesAllNodes(Iso.newEngland,
  //         LmpComponent.lmp, Date.utc(2017, 1, 1), Date.utc(2017, 1, 3));
  //     expect(data.length, 1136);
  //     var p321 = data[321]!;
  //     expect(p321.first.value, 37.755);
  //   });
  // });
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  DbProd();
  tests(dotenv.env['ROOT_URL']!);
}
