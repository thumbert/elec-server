library test.db.isoexpress.da_congestion_compact_test;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/api/isoexpress/api_isone_dacongestion.dart';
import 'package:elec_server/src/db/isoexpress/da_congestion_compact.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
//import 'package:dotenv/dotenv.dart' as dotenv;

import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/api/isoexpress/api_isone_dalmp.dart';
import 'package:elec_server/client/isoexpress/dacongestion_compact.dart'
    as client;
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

void tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  group('DAM congestion compact archive tests: ', () {
    var archive = DaCongestionCompactArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('process DA hourly lmp report, 2017-11-05', () {
      var file = archive.getFilename(Date.utc(2017, 11, 5));
      var res = archive.processFile(file);
      var congestion = res.first['congestion'] as List;
      expect(congestion.first,
          [0.67, 0, 2, 0.3, 0.84, 0.91, 0.75, 0, 11, 0.02, 6, 0.01, 1]);
    });
  });
  group('DAM LMP api tests: ', () {
    var db = DbProd.isoexpress;
    var api = DaCongestionCompact(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get congestion data for 2 days', () async {
      var aux = await api.getPrices(Date.utc(2019, 1, 1), Date.utc(2019, 1, 2));
      expect(aux.length, 2);
      expect(aux.first.keys.toList(), ['date', 'ptids', 'congestion']);
      var ptids = aux.first['ptids'] as List;
      expect(ptids.take(4).toList(), [321, 322, 323, 324]);
      var congestion = aux.first['congestion'] as List;
      expect((congestion.first as List).take(4).toList(), [0.02, 1, 0.01, 3]);
    });
  });
  group('DAM LMP client tests: ', () {
    var cong = client.DaCongestion(http.Client(), rootUrl: rootUrl);
    test('get hourly price for 1Jan19-5Jan19', () async {
      var data =
          await cong.getTraces(Date.utc(2019, 1, 1), Date.utc(2019, 1, 5));
      expect(data.length, 1191);
      var trace0 = data.first;
      expect(trace0.keys.toList(), ['x', 'y', 'name']);
      var y0 = trace0['y'] as List;
      expect(y0.length, 120);
      expect(y0.take(5).toList(), [0.02, 0.01, 0.01, 0.01, 0]);
    });
  });
}

void main() async {
  initializeTimeZones();
  // await DaCongestionCompactArchive().setupDb();

  DbProd();
  tests('http://127.0.0.1:8080');

//  Db db = new Db('mongodb://localhost/isoexpress');

  // await soloTest();
}
