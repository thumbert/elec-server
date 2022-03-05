library test.db.nyiso.da_congestion_compact_test;

import 'dart:convert';
import 'package:elec_server/api/api_dacongestion.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/nyiso/da_congestion_compact.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/dacongestion.dart' as client;

Future<void> tests(String rootUrl) async {
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
  group('Nyiso DAM congestion compact api tests: ', () {
    var api = DaCongestionCompact(DbProd.nyiso, iso: Iso.newYork);
    setUp(() async => await DbProd.nyiso.open());
    tearDown(() async => await DbProd.nyiso.close());
    test('get congestion prices data for 2 days', () async {
      var aux = await api.getPrices(Date.utc(2019, 1, 1), Date.utc(2019, 1, 2));
      expect(aux.length, 2);
      expect(aux.first.keys.toSet(), {'date', 'ptids', 'congestion'});
      expect(aux.first['date'], '2019-01-01');
      expect(aux.first['congestion'].length, 24);
      expect(aux.first['ptids'].length, 348);
      expect(aux.first['congestion'].first.take(4).toList(),
          [13, -32.33, 2, -25.08]);
      var url =
          '$rootUrl/nyiso/dacongestion/v1/start/2019-01-01/end/2019-01-02';
      var res = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.length, 2);
      expect(data.first.keys.toSet(), {'date', 'ptids', 'congestion'});
      expect(data.first['date'], '2019-01-01');
      expect(data.first['congestion'].length, 24);
    });
  });

  group('Nyiso DAM congestion compact client tests: ', () {
    var cong =
        client.DaCongestion(http.Client(), iso: Iso.newYork, rootUrl: rootUrl);
    test('get hourly traces for 1Jan19-5Jan19', () async {
      var data = await cong.getHourlyTraces(
          Date.utc(2019, 1, 1), Date.utc(2019, 1, 5));
      expect(data.length, 348);
      var trace0 = data.first;
      expect(trace0.keys.toList(), ['x', 'y', 'ptid']);
      var y0 = trace0['y'] as List;
      expect(y0.length, 120);
      expect(y0.take(5).toList(), [-32.33, -30.7, -8.12, -7.88, -8.23]);
    });
    test('speed test: get hourly traces for Jan19', () async {
      var sw = Stopwatch()..start();
      var data = await cong.getHourlyTraces(
          Date.utc(2019, 1, 1), Date.utc(2019, 1, 31));
      sw.stop();
      print(sw.elapsedMilliseconds);
      expect(sw.elapsedMilliseconds < 1000, true);
      expect(data.length, 348);
    });
  });
}

void main() async {
  initializeTimeZones();
  DbProd();
  tests('http://127.0.0.1:8080');
}
