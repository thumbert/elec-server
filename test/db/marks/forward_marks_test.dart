library test.client.forward_marks;

import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:tuple/tuple.dart';
import 'package:timeseries/timeseries.dart';

import '../../../bin/setup_db.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/marks/forward_marks.dart';
import 'package:elec_server/client/marks/forward_marks.dart' as client;
import 'package:elec_server/src/db/marks/curves/forward_marks.dart';
import 'package:test/test.dart';
import 'package:timezone/timezone.dart';

/// Get the curves that are directly marked
List<String> getMarkedCurveIds() {
  return [
    'isone_energy_4000_da_lmp',
    'isone_energy_4000_hourlyshape',
    'isone_energy_4001_da_basis',
    'isone_energy_4002_da_basis',
    'isone_energy_4003_da_basis',
    'isone_energy_4004_da_basis',
    'isone_energy_4005_da_basis',
    'isone_energy_4006_da_basis',
    'isone_energy_4007_da_basis',
    'isone_energy_4008_da_basis',
    'isone_energy_4011_da_lmp',
    'isone_energy_4011_da_basis',
    'isone_energy_4011_da_congestion',
    'isone_energy_4011_da_lossfactor',
    'isone_volatility_4000_da_daily',
    'pjm_energy_westernhub_da_lmp',
    ...['ng_henryhub', 'ng_algcg_gdm', 'ng_tetcom3_gdm'],
  ]..sort();
}

Future<void> tests(String rootUrl) async {
  var archive = ForwardMarksArchive();
  var location = getLocation('America/New_York');
  group('ForwardMarks archive tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('document equality, scalar', () {
      var document = <String, dynamic>{
        'fromDate': '2018-12-14',
        'curveId': 'isone_energy_4011_da_lmp',
        'markType': 'scalar',
        'terms': ['2019-01', '2019-02', '2019-12'],
        'buckets': {
          '5x16': <num>[89.10, 86.25, 71.05],
          '2x16H': <num>[72.19, 67.12, 42.67],
          '7x8': <num>[44.18, 39.73, 38.56],
        }
      };
      var newDocument = <String, dynamic>{
        'fromDate': '2018-12-15',
        'curveId': 'isone_energy_4011_da_lmp',
        'markType': 'scalar',
        'terms': ['2019-01', '2019-02', '2019-12'],
        'buckets': {
          '5x16': <num>[89.10, 86.25, 71.05],
          '2x16H': <num>[72.19, 67.12, 42.67],
          '7x8': <num>[44.18, 39.73, 38.56],
        }
      };
      expect(archive.needToInsert(document, newDocument), false);
    });
    test('document equality, scalar, up to 1E-6 tolerance', () {
      var document = <String, dynamic>{
        'fromDate': '2018-12-14',
        'curveId': 'isone_energy_4011_da_lmp',
        'markType': 'scalar',
        'terms': ['2019-01', '2019-02', '2019-12'],
        'buckets': {
          '5x16': [89.10, 86.25, 71.05],
          '2x16H': [72.19, 67.12, 42.67],
          '7x8': [44.18, 39.73, 38.56],
        }
      };
      var newDocument = <String, dynamic>{
        'fromDate': '2018-12-15',
        'curveId': 'isone_energy_4011_da_lmp',
        'markType': 'scalar',
        'terms': ['2019-01', '2019-02', '2019-12'],
        'buckets': {
          '5x16': [89.10000001, 86.25, 71.05],
          '2x16H': [72.19, 67.12, 42.67],
          '7x8': [44.18, 39.73, 38.56],
        }
      };
      expect(archive.needToInsert(document, newDocument), false);
    });
    test('document equality, volatilitySurface up to 1E-6 tolerance', () {
      var document = <String, dynamic>{
        'fromDate': '2018-12-14',
        'curveId': 'isone_volatility_4000_daily',
        'markType': 'volatilitySurface',
        'terms': ['2019-01', '2019-02', '2019-12'],
        'strikeRatio': [0.5, 1, 2],
        'buckets': {
          '5x16': [
            [89.10, 96.25, 101.05],
            [89.10, 96.25, 101.05],
            [69.10, 76.25, 89.05],
          ],
          '2x16H': [
            [62.19, 72.12, 82.67],
            [62.19, 72.12, 82.67],
            [42.19, 52.12, 62.67],
          ],
          '7x8': [
            [52.19, 55.12, 62.67],
            [52.19, 55.12, 62.67],
            [42.19, 45.12, 46.67],
          ],
        }
      };
      var newDocument = <String, dynamic>{
        'fromDate': '2018-12-15',
        'curveId': 'isone_volatility_4000_daily',
        'markType': 'volatilitySurface',
        'terms': ['2019-01', '2019-02', '2019-12'],
        'strikeRatio': [0.5, 1, 2],
        'buckets': {
          '5x16': [
            [89.1000001, 96.25, 101.05],
            [89.10, 96.25, 101.05],
            [69.10, 76.25, 89.05],
          ],
          '2x16H': [
            [62.19, 72.12, 82.67],
            [62.19, 72.12, 82.67],
            [42.19, 52.12, 62.67],
          ],
          '7x8': [
            [52.19, 55.12, 62.67],
            [52.19, 55.12, 62.67],
            [42.19, 45.12, 46.67],
          ],
        }
      };
      expect(archive.needToInsert(document, newDocument), false);
    });
    test('need to insert, different terms', () {
      var xOld = {
        'fromDate': '2020-08-17',
        'curveId': '1',
        'terms': ['2020-10', '2020-11', '2020-12', '2021-01', '2021-02'],
        'buckets': {
          '5x16': [5, 6, 7, 8, 9],
        }
      };
      var xNew = {
        'fromDate': '2020-08-17',
        'curveId': '1',
        'terms': ['2020-11-01', '2020-11-02', '2020-12', '2021-01', '2021-02'],
        'buckets': {
          '5x16': [6, 7, 8, 9, 10],
        }
      };
      expect(archive.needToInsert(xOld, xNew), true);
    });
    test('need to insert, different terms 2', () {
      var xOld = {
        'fromDate': '2020-08-17',
        'curveId': '1',
        'terms': ['2020-10', '2020-11', '2020-12', '2021-01', '2021-02'],
        'buckets': {
          '5x16': [5, 6, 7, 8, 9],
          '2x16H': [5.2, 6.2, 7.2, 8.2, 9.2],
          '7x8': [1.1, 2.1, 3.1, 4.1, 5.1],
        }
      };
      var xNew = {
        'fromDate': '2020-08-17',
        'curveId': '1',
        'terms': ['2020-11-01', '2020-11-02', '2020-12', '2021-01', '2021-02'],
        'buckets': {
          '5x16': [null, 6, 7, 8, 9],
          '2x16H': [6.2, null, 7.2, 8.2, 9.2],
          '7x8': [2.1, 2.1, 3.1, 4.1, 5.1],
        }
      };
      expect(archive.needToInsert(xOld, xNew), false);
    });
    test('getMarks for one day', () async {
      var hub = await ForwardMarksArchive.getDocument(
          '2020-07-06', 'isone_energy_4000_da_lmp', archive.dbConfig.coll);
      expect(hub['terms'].first, '2020-07-07');
      var hs = await ForwardMarksArchive.getDocument(
          '2020-07-06', 'isone_energy_4000_hourlyshape', archive.dbConfig.coll);
      expect(hs['terms'].first, '2020-01');
      var vs = await ForwardMarksArchive.getDocument('2020-07-06',
          'isone_volatility_4000_da_daily', archive.dbConfig.coll);
      expect(vs['terms'].first, '2020-08');
    });

    test('if you try a curve before first mark date return empty', () async {
      var hub = await ForwardMarksArchive.getDocument(
          '2020-05-01', 'isone_energy_4000_da_lmp', archive.dbConfig.coll);
      expect(hub.isEmpty, true);
    });

    test('getMarks for one curve, multiple days', () async {
      var marks = await ForwardMarksArchive.getDocumentsOneCurveStartEnd(
          'isone_energy_4000_da_lmp',
          archive.dbConfig.coll,
          '2020-05-15',
          '2020-08-01');
      expect(marks.length, 2);
      expect(marks.first['fromDate'], '2020-05-29');
      expect(marks.first['terms'].first, '2020-05');
      expect(marks.last['fromDate'], '2020-07-06');
      expect(marks.last['terms'].first, '2020-07-07');
    });

    test('getMarks for one curve, multiple days non spanning a mark', () async {
      var marks = await ForwardMarksArchive.getDocumentsOneCurveStartEnd(
          'isone_energy_4000_da_lmp',
          archive.dbConfig.coll,
          '2020-05-31',
          '2020-07-01');
      expect(marks.length, 1); // only the mark from 2020-05-29 exists!
      expect(marks.first['fromDate'], '2020-05-29');
      expect(marks.first['terms'].first, '2020-05');
    });
  });

  //-----------------------------------------------------------------
  group('ForwardMarks api tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    var api = ForwardMarks(archive.db);
    var allCurveIds = {
      ...getMarkedCurveIds(),
    };
    test('api get all curveIds', () async {
      var aux = await http.get(Uri.parse('$rootUrl/forward_marks/v1/curveIds'),
          headers: {'Content-Type': 'application/json'});
      var res = json.decode(aux.body) as List;
      expect(allCurveIds.containsAll(res), true);
    });
    test('api get all curveIds with pattern', () async {
      var res = await api.getCurveIdsContaining('isone');
      expect(
          allCurveIds
              .where((e) => e.contains('isone'))
              .toSet()
              .containsAll(res),
          true);
    });
    test('api get all available fromDates for a curveId', () async {
      var res = await api.getFromDatesForCurveId('isone_energy_4000_da_lmp');
      expect(res.length >= 2, true);
    });
    test('api get all available fromDates for a spread curve', () async {
      var res = await api.getFromDatesForCurveId('isone_energy_4004_da_basis');
      expect(res.isNotEmpty, true);
    });
    test('curve details cache speed', () async {
      var sw = Stopwatch()..start();
      await ForwardMarks.curveIdCache.get('isone_energy_4000_da_lmp');
      sw.stop();
      expect(sw.elapsedMilliseconds < 10, true); // 2 ms on the laptop
    });
    test('Return an empty map if date is before first date', () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4000_da_lmp/'
              'asOfDate/2020-05-01'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;
      expect(data.isEmpty, true);
    });
    test(
        'get mh forward curve as of 5/29/2020, May20 mark gets expanded'
        'to daily', () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4000_da_lmp/'
              'asOfDate/2020-05-29'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect(data['terms'].first, '2020-05-30');
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect(data['buckets']['5x16'][0], null); // it's a Saturday
    });
    test('get mh forward curve as of 7/6/2020, direct', () async {
      var xs = await api.getForwardCurve(
          Date.utc(2020, 7, 6), 'isone_energy_4000_da_lmp') as PriceCurve;
      expect(xs.length, 90);
      expect(xs.firstMonth, Month(2020, 8, location: location));
      expect(xs.first.value, {Bucket.b5x16: 23.48, Bucket.b7x8: 15.5});
    });
    test('get mh forward curve as of 7/6/2020, http', () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4000_da_lmp/'
              'asOfDate/2020-07-06'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
    });
    test('cache of curveDetails', () async {
      var res =
          await (ForwardMarks.curveIdCache.get('isone_energy_4004_da_lmp'));
      expect(res!['children'].toSet(),
          {'isone_energy_4000_da_lmp', 'isone_energy_4004_da_basis'});
    });
    test('get one composite forward curve, add 2', () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4004_da_lmp/'
              'asOfDate/2020-07-06'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect(data['terms'][0], '2020-07-07');
      expect(data['terms'][30], '2021-01');
      expect((data['buckets']['5x16'][30] as num).toStringAsFixed(2), '60.05');
    });
    test('get one composite forward curve, nodal mark', () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4011_da_lmp/'
              'asOfDate/2020-07-06'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;

      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect(data['terms'][0], '2020-07-07');
      expect(data['terms'][30], '2021-01');
      var lmpJan21 = 60.7 + 0.57 + 60.7 * 0.031;
      expect((data['buckets']['5x16'][30] as num).toStringAsFixed(4),
          lmpJan21.toStringAsFixed(4));
    });
    test('get one composite forward curve, subtract two curves', () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4011_da_basis/'
              'asOfDate/2020-07-06'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect(data['terms'][0], '2020-07-07');
      expect(data['terms'][30], '2021-01');
      var lmpJan21 = 0.57 + 60.7 * 0.031;
      expect((data['buckets']['5x16'][30] as num).toStringAsFixed(4),
          lmpJan21.toStringAsFixed(4));
    });
    test('get one forward curve, all marked buckets', () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4000_da_lmp/'
              'asOfDate/2020-07-10'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect((data['terms'] as List)[0], '2020-07-11');
      expect((data['terms'] as List).last, '2025-12');
      expect((data['terms'] as List).length, 86);
      expect((data['buckets']['5x16'] as List).length, 86);
    });
    test('get one hourlyshape curve, isone_energy_4000_hourlyshape', () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4000_hourlyshape/'
              'asOfDate/2020-07-10'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect((data['terms'] as List).first, '2020-07');
      expect((data['terms'] as List).length, 78);
      var v5x16 = data['buckets']['5x16'] as List;
      expect(v5x16.length, 78);
      expect((v5x16.first as List).length, 16); // shape for the 16 hours
    });
    test('get one forward curve, all marked buckets, daily + monthly',
        () async {
      var aux = await http.get(
          Uri.parse('$rootUrl/forward_marks/v1/'
              'curveId/isone_energy_4000_da_lmp/'
              'asOfDate/2020-07-10'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(aux.body) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect((data['terms'] as List).length, 86);
      expect((data['terms'] as List).first, '2020-07-11');
      expect((data['buckets']['5x16'] as List).length, 86);
      expect((data['buckets']['5x16'] as List).first, null); // weekend
    });
    test('get the buckets marked for one curve', () async {
      // marked curve
      var b0 = await api.getBucketsMarked('isone_energy_4000_da_lmp');
      expect(b0, {'5x16', '2x16H', '7x8'});
      // composite curve
      var b1 = await api.getBucketsMarked('isone_energy_4004_da_lmp');
      expect(b1, {'5x16', '2x16H', '7x8'});
      // fuel curve
      var b2 = await api.getBucketsMarked('ng_henryhub');
      expect(b2, {'7x24'});
    });

    test('fill marksCache in bulk', () async {
      await ForwardMarks.marksCache.invalidateAll();
      var start = Date.utc(2020, 5, 29);
      var end = Date.utc(2020, 7, 6);
      await api.fillMarksCacheBulk('isone_energy_4000_da_lmp', start, end);
      expect(await ForwardMarks.marksCache.size(), 39);
      var jan21 = Month(2021, 1, location: location);
      var feb21 = Month(2021, 2, location: location);

      var p529 = await api.getForwardCurve(
          Date.utc(2020, 7, 5), 'isone_energy_4000_da_lmp') as PriceCurve;
      expect(await ForwardMarks.marksCache.size(), 39); // in the cache already
      expect(p529.first.interval, Date(2020, 7, 6, location: location));
      expect(p529.first.value[Bucket.b5x16], 25.4); // the value as of 5/29/2020
      expect(p529.value(jan21, Bucket.b5x16), 58.25);
      expect(p529.value(feb21, Bucket.b5x16), 55.75);

      var p76 = await api.getForwardCurve(
          Date.utc(2020, 7, 6), 'isone_energy_4000_da_lmp') as PriceCurve;
      expect(p76.value(jan21, Bucket.b5x16), 60.7);
      expect(p76.value(feb21, Bucket.b5x16), 57.2);
    });

    test('fill marksCache in bulk, take 2', () async {
      await ForwardMarks.marksCache.invalidateAll();
      var start = Date.utc(2020, 7, 5);
      var end = Date.utc(2020, 7, 7);
      await api.fillMarksCacheBulk('isone_energy_4000_da_lmp', start, end);
      expect(await ForwardMarks.marksCache.size(), 3);
      var jan21 = Month(2021, 1, location: location);
      var feb21 = Month(2021, 2, location: location);

      var p75 = await ForwardMarks.marksCache
              .get(Tuple2(Date.utc(2020, 7, 5), 'isone_energy_4000_da_lmp'))
          as PriceCurve;
      expect(p75.first.interval, Date(2020, 7, 6, location: location));
      expect(p75.first.value[Bucket.b5x16], 25.4); // the value as of 5/29/2020
      expect(p75.value(jan21, Bucket.b5x16), 58.25);
      expect(p75.value(feb21, Bucket.b5x16), 55.75);

      var p76 = await ForwardMarks.marksCache
              .get(Tuple2(Date.utc(2020, 7, 6), 'isone_energy_4000_da_lmp'))
          as PriceCurve;
      expect(p76.value(jan21, Bucket.b5x16), 60.7);
      expect(p76.value(feb21, Bucket.b5x16), 57.2);

      var p77 = await ForwardMarks.marksCache
              .get(Tuple2(Date.utc(2020, 7, 7), 'isone_energy_4000_da_lmp'))
          as PriceCurve;
      expect(p77.value(jan21, Bucket.b5x16), 60.7);
      expect(p77.value(feb21, Bucket.b5x16), 57.2);
    });

    test('get a strip price between start/end dates', () async {
      var term = Term.parse('Jan21-Feb21', location);
      var bucket = Bucket.b5x16;
      var price = await api.getStripPrice('isone_energy_4000_da_lmp', term,
          bucket, Date.utc(2020, 5, 29), Date.utc(2020, 7, 7));
      expect(price.length, 40);
      expect(price['2020-05-29'], 57.0);
      expect(price['2020-05-30'], 57.0);
      expect(price['2020-07-06'], 58.95);
      expect(price['2020-07-07'], 58.95);
    });

    test('get the values for a strip between start/end dates', () async {
      var term = Term.parse('Jan21-Feb21', location);
      var bucket = Bucket.b5x16;
      var price = await api.getStripPriceValues('isone_energy_4000_da_lmp',
          term, bucket, Date.utc(2020, 5, 29), Date.utc(2020, 7, 7));
      expect(price.length, 40);
      expect(price['2020-05-29'], [58.25, 55.75]);
      expect(price['2020-05-30'], [58.25, 55.75]);
      expect(price['2020-07-06'], [60.7, 57.2]);
      expect(price['2020-07-07'], [60.7, 57.2]);
    });

    test('get an empty map for a strip for dates before first marked date',
        () async {
      var term = Term.parse('Jan21-Feb21', location);
      var bucket = Bucket.b5x16;
      var price = await api.getStripPrice('isone_energy_4000_da_lmp', term,
          bucket, Date.utc(2020, 5, 1), Date.utc(2020, 5, 10));
      expect(price.isEmpty, true);
    });
  });

  // Client tests ---------------------------------------------------------
  group('ForwardMarks client tests:', () {
    var clientFm = client.ForwardMarks(Client(), rootUrl: rootUrl);
    var location = getLocation('America/New_York');
    test('get mh curve as of 5/29/2020 for all buckets', () async {
      var curveId = 'isone_energy_4000_da_lmp';
      var res = await clientFm.getForwardCurve(curveId, Date.utc(2020, 5, 29),
          tzLocation: location);
      expect(res[0].interval, Date(2020, 5, 30, location: location));
      expect(res.length, 81);
      var jan21 = res.observationAt(Month(2021, 1, location: location));
      expect(jan21.value[IsoNewEngland.bucket5x16], 58.25);
    });
    test('get mh Jan21-Feb21 5x16 strip price', () async {
      var curveId = 'isone_energy_4000_da_lmp';
      var term = Term.parse('Jan21-Feb21', location);
      var res = await clientFm.getStripPrice(curveId, term, Bucket.b5x16,
          Date.utc(2020, 5, 29), Date.utc(2020, 7, 10));
      expect(res[0],
          IntervalTuple<num>(Date(2020, 5, 29, location: location), 57.0));
      expect(res[1],
          IntervalTuple<num>(Date(2020, 5, 30, location: location), 57.0));
      expect(res[37],
          IntervalTuple<num>(Date(2020, 7, 5, location: location), 57.0));
      expect(res[38],
          IntervalTuple<num>(Date(2020, 7, 6, location: location), 58.95));
    });

    test('get mh curve as of 7/6/2020 for all buckets', () async {
      var curveId = 'isone_energy_4000_da_lmp';
      var res = await clientFm.getForwardCurve(curveId, Date.utc(2020, 7, 6),
          tzLocation: location);
      expect(res[0].interval, Date(2020, 7, 7, location: location));
      expect(res.length, 90);
      var jan21 = res.observationAt(Month(2021, 1, location: location));
      expect(jan21.value[IsoNewEngland.bucket5x16], 60.7);
    });
    test('get mh hourly shape as of 5/29/2020 for all buckets', () async {
      var curveId = 'isone_energy_4000_hourlyshape';
      var hs = await clientFm.getHourlyShape(curveId, Date.utc(2020, 5, 29),
          tzLocation: location);
      expect(hs.buckets.length, 3);
      expect(
          hs.data.first.interval.start.location.toString(), 'America/New_York');
    });
    test('get mh volatility surface as of 7/6/2020', () async {
      var curveId = 'isone_volatility_4000_da_daily';
      var vs = await clientFm.getVolatilitySurface(
          curveId, Date(2020, 7, 6, location: location));
      expect(vs.strikeRatios, [0.5, 1, 2]);
    });
  });
}

/// Some data for testing.
void insertMarks() => insertForwardMarks();

Future<void> main() async {
  initializeTimeZones();

  // await insertMarks();

  // dotenv.load('.env/prod.env');
  var rootUrl = 'http://127.0.0.1:8080';
  await tests(rootUrl);
}
