library test.db.nyiso.da_congestion_compact_test;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/nyiso/da_congestion_compact.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/nyiso/da_lmp_hourly.dart';
import 'package:elec_server/api/api_dalmp.dart';
import 'package:elec_server/client/dalmp.dart' as client;
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

void tests(String rootUrl) async {
  group('Nyiso DAM congestion compact db tests: ', () {
    var archive = NyisoDaCongestionCompactArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('process 2019-01-01 (zones + gen nodes)', () async {
      var res = archive.processDay(Date.utc(2019, 1, 1));
      var congestion = res['congestion'] as List;
      expect(congestion.length, 24);
      expect(congestion[0].take(2).toList(), [14, -32.33]);

      /// How good is the compression?  For 2019-01-01 there are
      /// 570x24 (=13680) values that get stored as a 7556 list.
      /// For 2019-04-01, 13704 values get stored as a 5070 list.
      /// For 2019-06-01, 13704 values get stored as a 7286 list.
      ///
      // var count = 0;
      // for (List e in congestion) {
      //   count += e.length;
      // }
      // print(count);
    });
  });
  // group('Nyiso DAM LMP api tests: ', () {
  //   var api = DaLmp(DbProd.nyiso);
  //   setUp(() async => await DbProd.nyiso.open());
  //   tearDown(() async => await DbProd.nyiso.close());
  //   test('get lmp data for 2 days', () async {
  //     var aux = await api.getHourlyData(
  //         61757, Date.utc(2019, 1, 1), Date.utc(2019, 1, 2), 'lmp');
  //     expect(aux.length, 2);
  //     expect(aux['2019-01-01']!.take(3), [26.4, 22.97, 20.99]);
  //     var url = '$rootUrl/nyiso/dalmp/v1/hourly/lmp/'
  //         'ptid/61757/start/2019-01-01/end/2019-01-02';
  //     var res = await http
  //         .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
  //     var data = json.decode(res.body) as Map;
  //     expect(data.length, 2);
  //     expect(data['2019-01-01']!.take(3), [26.4, 22.97, 20.99]);
  //   });
  //   // test('get lmp data for 2 days (compact)', () async {
  //   //   var aux = await api.getHourlyPricesCompact(
  //   //       'lmp', 4000, '2017-01-01', '2017-01-02');
  //   //   expect(aux.length, 48);
  //   //   expect(aux.first, 35.12);
  //   // });
  //
  //   test('get daily lmp prices by peak bucket', () async {
  //     var data = await api.getDailyBucketPrice(
  //         'lmp', 61757, '2019-01-01', '2019-01-07', '5x16');
  //     expect(data.length, 4);
  //     expect(data.first, {'date': '2019-01-02', 'lmp': 36.040000000000006});
  //     var res = await http.get(
  //         Uri.parse('$rootUrl/nyiso/dalmp/v1/daily/lmp/'
  //             'ptid/61757/start/2019-01-01/end/2019-01-07/bucket/5x16'),
  //         headers: {'Content-Type': 'application/json'});
  //     var aux = json.decode(res.body) as List;
  //     expect(aux.length, 4);
  //     expect(aux.first, {'date': '2019-01-02', 'lmp': 36.040000000000006});
  //   });
  //
  //   test('get daily lmp prices by flat bucket', () async {
  //     var data = await api.getDailyBucketPrice(
  //         'lmp', 61757, '2019-01-01', '2019-01-07', 'flat');
  //     expect(data[1]['lmp'], 32.415416666666665);
  //     expect(data.length, 7);
  //   });
  //
  //   test('get mean daily 7x24 prices all nodes 2019-01-01 (mongo)', () async {
  //     var data = await api.dailyPriceByPtid('lmp', '2019-01-01', '2019-01-01');
  //     var capitl = data.firstWhere((e) => e['ptid'] == 61757);
  //     expect((capitl['lmp'] as num).toStringAsFixed(4), '25.8650');
  //     expect(data.length, 570);
  //   });
  //   test('get monthly lmp prices by flat bucket', () async {
  //     var data = await api.getMonthlyBucketPrice(
  //         'lmp', 61757, '201901', '201902', 'flat');
  //     expect(data.length, 2);
  //     expect(data.first, {'month': '2019-01', 'lmp': 51.03111559139784});
  //   });
  // });
  // group('DAM LMP speed tests: ', () {
  //   var api = DaLmp(DbProd.nyiso);
  //   var sw = Stopwatch();
  //   setUp(() async => await DbProd.nyiso.open());
  //   tearDown(() async => await DbProd.nyiso.close());
  //   test('hourly lmp', () async {
  //     /// 43 ms for one ptid 365 days, 55 ms for 700 days.
  //     /// 28 ms just the db query to select one node for 365 days, 40 ms for 700 days.
  //     sw.start();
  //     var aux = await api.getHourlyData(
  //         61757, Date.utc(2019, 2, 14), Date.utc(2020, 1, 13), 'congestion');
  //     sw.stop();
  //     expect(sw.elapsedMilliseconds, lessThan(100));
  //     expect(aux.containsKey('2019-02-14'), true);
  //   });
  //   test('get mean daily lmp prices all nodes 2017-01-01 (mongo)', () async {
  //     sw.reset();
  //     sw.start();
  //     var data = await api.dailyPriceByPtid('lmp', '2019-02-14', '2020-02-13');
  //     sw.stop();
  //     expect(sw.elapsedMilliseconds, lessThan(3000));
  //     expect(data.length, 208891);
  //   });
  // });

  // group('DAM LMP client tests: ', () {
  //   var daLmp = client.DaLmp(http.Client(), rootUrl: rootUrl);
  //   test('get daily peak price between two dates', () async {
  //     var data = await daLmp.getDailyLmpBucket(4000, LmpComponent.lmp,
  //         IsoNewEngland.bucket5x16, Date.utc(2017, 1, 1), Date.utc(2017, 1, 5));
  //     expect(data.length, 3);
  //     expect(data.toList(), [
  //       IntervalTuple(Date(2017, 1, 3, location: location), 45.64124999999999),
  //       IntervalTuple(Date(2017, 1, 4, location: location), 39.103125),
  //       IntervalTuple(Date(2017, 1, 5, location: location), 56.458749999999995)
  //     ]);
  //   });
  //   test('get monthly peak price between two dates', () async {
  //     var data = await daLmp.getMonthlyLmpBucket(4000, LmpComponent.lmp,
  //         IsoNewEngland.bucket5x16, Month.utc(2017, 1), Month.utc(2017, 8));
  //     expect(data.length, 8);
  //     expect(data.first,
  //         IntervalTuple(Month(2017, 1, location: location), 42.55883928571426));
  //   });
  //   test('get hourly price for 2017-01-01', () async {
  //     var data = await daLmp.getHourlyLmp(
  //         4000, LmpComponent.lmp, Date.utc(2017, 1, 1), Date.utc(2017, 1, 1));
  //     expect(data.length, 24);
  //     expect(
  //         data.first,
  //         IntervalTuple(
  //             Hour.beginning(TZDateTime(location, 2017, 1, 1)), 35.12));
  //   });
  //   test('get daily prices all nodes', () async {
  //     var data = await daLmp.getDailyPricesAllNodes(
  //         LmpComponent.lmp, Date.utc(2017, 1, 1), Date.utc(2017, 1, 3));
  //     expect(data.length, 1136);
  //     var p321 = data[321]!;
  //     expect(p321.first.value, 37.755);
  //   });
  // });
}

void main() async {
  initializeTimeZones();
  DbProd();
  tests('http://127.0.0.1:8080');
}
