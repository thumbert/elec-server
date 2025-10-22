import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/isoexpress/da_congestion_compact.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/dacongestion.dart' as client;

Future<void> tests() async {
  final rootUrl = dotenv.env['ROOT_URL']!;
  final rustServer = dotenv.env['RUST_SERVER']!;

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
      expect(congestion.first.toList(), [
        1,
        -6.09,
        1215,
        0,
      ]);
    });
  });
  group('DA congestion compact client tests: ', () {
    test('ISONE hourly traces for 15Oct25-16Oct25', () async {
      var cong = client.DaCongestion(http.Client(),
          rootUrl: rootUrl, iso: Iso.newEngland, rustServer: rustServer);
      var data = await cong.getHourlyTraces(
          Date.utc(2025, 10, 15), Date.utc(2025, 10, 16));
      expect(data.length, 1213);
      var trace0 = data.firstWhere((e) => e['ptid'] == 12530);
      expect(trace0.keys.toList(), ['x', 'y', 'ptid']);
      var y0 = trace0['y'] as List;
      expect(y0.length, 48);
      expect(y0.take(8).toList(), [0, 0, 0, 0, 0, 0, 0.04, -26.28]);
    });
    test('NYISO hourly traces for 15Oct25-16Oct25', () async {
      var cong = client.DaCongestion(http.Client(),
          rootUrl: rootUrl, iso: Iso.newYork, rustServer: rustServer);
      var data = await cong.getHourlyTraces(
          Date.utc(2025, 10, 15), Date.utc(2025, 10, 16));
      expect(data.length, 761);
      var trace0 = data.firstWhere((e) => e['ptid'] == 23528);
      expect(trace0.keys.toList(), ['x', 'y', 'ptid']);
      var y0 = trace0['y'] as List;
      expect(y0.length, 48);
      expect(y0.take(9).toList(), [0, 0, 0, 0, 0, 0, 0, -1.14, -1.09]);
    });
    // test('IESO hourly traces for 15Oct25-16Oct25', () async {
    //   var cong = client.DaCongestion(http.Client(),
    //       rootUrl: rootUrl, iso: Iso.ieso, rustServer: rustServer);
    //   var data = await cong.getHourlyTraces(
    //       Date.utc(2025, 10, 15), Date.utc(2025, 10, 16));
    //   expect(data.length, 761);
    //   var trace0 = data.firstWhere((e) => e['ptid'] == 23528);
    //   expect(trace0.keys.toList(), ['x', 'y', 'ptid']);
    //   var y0 = trace0['y'] as List;
    //   expect(y0.length, 48);
    //   expect(y0.take(9).toList(), [0, 0, 0, 0, 0, 0, 0, -1.14, -1.09]);
    // });
    test('speed test', () async {
      var cong = client.DaCongestion(http.Client(),
          rootUrl: rootUrl, iso: Iso.newEngland, rustServer: rustServer);
      var sw = Stopwatch()..start();
      var data = await cong.getHourlyTraces(
          Date.utc(2024, 10, 1), Date.utc(2024, 10, 30));
      sw.stop();
      expect(data.length > 1191, true);
      // Used to be 800ms with the old api using rle and Mongo
      // With rust server and compact format it's ~1300ms.
      // print(sw.elapsedMilliseconds);
      expect(sw.elapsedMilliseconds < 2000, true);
    });
  });
}

void main() async {
  initializeTimeZones();
  DbProd();
  dotenv.load('.env/prod.env');

  await tests();
}
