library test.db.isoexpress.da_congestion_compact_test;

import 'package:elec/elec.dart';
import 'package:elec_server/api/api_dacongestion.dart';
import 'package:elec_server/src/db/isoexpress/da_congestion_compact.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/dacongestion.dart' as client;
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  group('Isone DAM congestion compact archive tests: ', () {
    var archive = DaCongestionCompactArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('process DA hourly lmp report, 2017-11-05', () {
      // this is DST fall back time, 25 hours
      var file = archive.getFilename(Date.utc(2017, 11, 5), extension: 'csv');
      var res = archive.processFile(file);
      var congestion = res.first['congestion'] as List;
      expect(congestion.length, 25);
      expect(congestion.first.take(8).toList(),
          [1, -59.19, 1, -9.83, 1, -9.22, 2, -7.35]);
    });
    test('process DA hourly lmp report, 2019-01-02', () {
      // excellent compression!
      var file = archive.getFilename(Date.utc(2019, 1, 2), extension: 'csv');
      var res = archive.processFile(file);
      var congestion = res.first['congestion'] as List;
      expect(congestion.length, 24);
      expect(congestion.first.toList(),
          [8, -17.66, 1, -2.13, 1, -0.26, 1181, 0.03]);
    });
    test('process DA hourly lmp report json format, 2022-12-22', () {
      // amazing compression!
      var file = archive.getFilename(Date.utc(2022, 12, 22));
      var res = archive.processFile(file);
      var congestion = res.first['congestion'] as List;
      expect(congestion.length, 24);
      expect(congestion.first.toList(), [1, -6.09, 1215, 0,]);
    });
  });
  group('Isone DA Congestion compact api tests: ', () {
    var db = DbProd.isoexpress;
    var api = DaCongestionCompact(db, iso: Iso.newEngland);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get congestion data for 2 days', () async {
      var aux = await api.getPrices(Date.utc(2019, 1, 1), Date.utc(2019, 1, 2));
      expect(aux.length, 2);
      expect(aux.first.keys.toList(), ['date', 'ptids', 'congestion']);
      var ptids = aux.first['ptids'] as List;
      // expect(ptids.take(4).toList(), [35979, 12530, 43790, 424]);
      expect(ptids.take(4).toList(), [35979, 12530, 43790, 37175]);
      var congestion = aux.first['congestion'] as List;
      expect(congestion.length, 24);
      expect(
          (congestion.first as List).take(4).toList(), [2, -13.73, 8, -7.52]);
    });
  });
  group('Isone DA congestion compact client tests: ', () {
    var cong = client.DaCongestion(http.Client(),
        rootUrl: rootUrl, iso: Iso.newEngland);
    // test('get cache term', () async {
    //   var t1 =
    //       cong.calculateStartEnd(Date.utc(2019, 1, 1), Date.utc(2019, 1, 5));
    //   expect(t1, Term.parse('Jan19', UTC));
    //   var data = await cong.getHourlyTraces(
    //       Date.utc(2019, 1, 1), Date.utc(2019, 1, 5));
    //   var t2 =
    //       cong.calculateStartEnd(Date.utc(2021, 10, 1), Date.utc(2021, 10, 5));
    //   expect(t2, Term.parse('Oct21', UTC));
    // }, solo: true);
    test('get hourly traces for 1Jan19-5Jan19', () async {
      var data = await cong.getHourlyTraces(
          Date.utc(2019, 1, 1), Date.utc(2019, 1, 5));
      expect(data.length, 1191);
      var trace0 = data.first;
      expect(trace0.keys.toList(), ['x', 'y', 'ptid']);
      var y0 = trace0['y'] as List;
      expect(y0.length, 120);
      expect(y0.take(5).toList(), [-13.73, -5.7, -3.4, -3.16, -1.21]);
    });
    // test('get daily traces for 1Jan19-5Jan19', () async {
    //   var data =
    //       await cong.getDailyTraces(Date.utc(2019, 1, 1), Date.utc(2019, 1, 5));
    //   expect(data.length, 1191);
    //   var trace0 = data.first;
    //   expect(trace0.keys.toList(), ['x', 'y', 'ptid']);
    //   var y0 = trace0['y'] as List;
    //   expect(y0.length, 5);
    //   expect(y0.map((e) => e.toStringAsFixed(3)).toList(),
    //       ['0.013', '0.007', '-0.253', '0.004', '0.000']);
    // });
    test('speed test', () async {
      var sw = Stopwatch()..start();
      var data = await cong.getHourlyTraces(
          Date.utc(2021, 10, 1), Date.utc(2021, 10, 30));
      sw.stop();
      expect(data.length > 1191, true);
      expect(sw.elapsedMilliseconds < 400, true);
    });
  });
}

void main() async {
  initializeTimeZones();
  // await DaCongestionCompactArchive().setupDb();

  DbProd();
  tests('http://127.0.0.1:8080');
}
