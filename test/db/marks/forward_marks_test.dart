library test.client.forward_marks;

import 'dart:convert';
import 'dart:math';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/marks/forward_marks.dart';
import 'package:elec_server/client/marks/forward_marks.dart' as client;
import 'package:elec_server/src/db/marks/curves/forward_marks.dart';
import 'package:test/test.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:timezone/standalone.dart';

import 'marks_special_days.dart';
import 'package:elec/src/time/shape/hourly_shape.dart';

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
    'isone_energy_4011_da_basis',
    'isone_volatility_4000_daily',
    'pjm_energy_westernhub_da_lmp',
    ...['ng_henryhub', 'ng_algcg_gdm', 'ng_tetcom3_gdm'],
  ]..sort();
}

void insertData(ForwardMarksArchive archive) async {
  var location = getLocation('America/New_York');
  var start = Date(2018, 1, 1, location: location);
  var end = Date(2018, 12, 31, location: location);
  var calendar = NercCalendar();
  var days = Interval(start.start, end.end)
      .splitLeft((dt) => Date.fromTZDateTime(dt))
      .where((date) => !date.isWeekend())
      .where((date) => !calendar.isHoliday(date))
      .toList();
  var endMonth = Month(2025, 12, location: location);
  var rand = Random(0);

  var curveIds = getMarkedCurveIds();
  for (var curveId in curveIds) {
    print(curveId);
    var data;
    if (curveId.contains('_energy_')) {
      data = _generateDataElecCurve(curveId, days, endMonth, rand);
    } else if (curveId.startsWith('ng')) {
      data = _generateDataNgCurve(curveId, days, endMonth, rand);
    } else {
      throw StateError('unimplemented curve $curveId');
    }
    await archive.insertData(data);
  }
}

/// Generate forward curve data for one curve for a list of days.  Random data.
/// Spread curves only get marked on the first day of the month.
List<Map<String, dynamic>> _generateDataElecCurve(
    String curveId, List<Date> days, Month endMonth, Random rand) {
  var out = <Map<String, dynamic>>[];
  var multiplier = curveId.contains('spread') ? 0.05 : 1.0;
  var calendar = NercCalendar();
  for (var day in days) {
    var month0 = Month(day.year, day.month, location: day.location);
    var months = month0.next.upTo(endMonth);
    var n = months.length;
    if (curveId.contains('basis') &&
        day != calendar.firstBusinessDate(month0)) {
      continue;
    }
    out.add({
      'fromDate': day.toString(),
      'curveId': curveId,
      'markType': 'monthly',
      'terms': months.map((e) => e.toIso8601String()).toList(),
      'buckets': {
        '5x16':
            List.generate(n, (i) => 45 * multiplier + 2 * rand.nextDouble()),
        '2x16H':
            List.generate(n, (i) => 33 * multiplier + 2 * rand.nextDouble()),
        '7x8': List.generate(n, (i) => 20 * multiplier + 2 * rand.nextDouble()),
      }
    });
  }
  return out;
}

List<Map<String, dynamic>> _generateDataNgCurve(
    String curveId, List<Date> days, Month endMonth, Random rand) {
  var out = <Map<String, dynamic>>[];
  for (var day in days) {
    var month0 = Month(day.year, day.month, location: day.location);
    var months = month0.next.upTo(endMonth);
    var n = months.length;
    out.add({
      'fromDate': day.toString(),
      'curveId': curveId,
      'markType': 'monthly',
      'terms': months.map((e) => e.toIso8601String()).toList(),
      'buckets': {
        '7x24': List.generate(n, (i) => 2 + rand.nextDouble()),
      },
    });
  }
  return out;
}

void tests(String rootUrl) async {
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
    test('getMarks', () async {
      var hub = await ForwardMarksArchive.getDocument(
          '2020-07-06', 'isone_energy_4000_da_lmp', archive.dbConfig.coll);
      expect(hub['terms'].first, '2020-07-07');
      var hs = await ForwardMarksArchive.getDocument(
          '2020-07-06', 'isone_energy_4000_hourlyshape', archive.dbConfig.coll);
      expect(hs['terms'].first, '2020-01');
      var vs = await ForwardMarksArchive.getDocument(
          '2020-07-06', 'isone_volatility_4000_daily', archive.dbConfig.coll);
      expect(vs['terms'].first, '2020-08');
    });
  });

  group('ForwardMarks api tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    var api = ForwardMarks(archive.db);
    var allCurveIds = {
      ...getMarkedCurveIds(),
    };
    test('api get all curveIds', () async {
      var res = await api.getCurveIds();
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
      await api.curveIdCache.get('isone_energy_4000_da_lmp');
      sw.stop();
      expect(sw.elapsedMilliseconds < 10, true); // 2 ms on the laptop
    });
    test('get one simple forward curve, all marked buckets', () async {
      var res =
          await api.getForwardCurve('isone_energy_4000_da_lmp', '2020-07-06');
      var data = json.decode(res.result) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
    });
    test('cache of curveDetails', () async {
      var res = await api.curveIdCache.get('isone_energy_4004_da_lmp');
      expect(res['children'].toSet(),
          {'isone_energy_4000_da_lmp', 'isone_energy_4004_da_basis'});
    });
    test('get one composite forward curve, all marked buckets, monthly',
        () async {
      expect(
          await api.marksCache.size(), 1); // only the hub, monthly is in cache
      var res =
          await api.getForwardCurve('isone_energy_4004_da_lmp', '2020-07-06');
      var data = json.decode(res.result) as Map<String, dynamic>;
      expect(await api.curveIdCache.size(), 3);

      /// now there are 3 curves in the cache: hub, ct basis, ct lmp
      expect(await api.marksCache.size(), 3);
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect(data['terms'][0], '2020-07-07');
      expect(data['terms'][30], '2021-01');
      expect((data['buckets']['5x16'][30] as num).toStringAsFixed(2), '60.05');
    });
    test('get one forward curve, all marked buckets', () async {
      var res =
          await api.getForwardCurve('isone_energy_4000_da_lmp', '2020-07-10');
      var data = json.decode(res.result) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect((data['terms'] as List)[0], '2020-07-11');
      expect((data['terms'] as List).last, '2021-12');
      expect((data['terms'] as List).length, 38);
      expect((data['buckets']['5x16'] as List).length, 38);
    });
    test('get one hourlyshape curve, isone_energy_4000_hourlyshape', () async {
      var res = await api.getForwardCurve(
          'isone_energy_4000_hourlyshape', '2020-07-10');
      var data = json.decode(res.result) as Map<String, dynamic>;
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
      var res =
          await api.getForwardCurve('isone_energy_4000_da_lmp', '2020-07-10');
      var data = json.decode(res.result) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'terms', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
      expect((data['terms'] as List).length, 38);
      expect((data['terms'] as List).first, '2020-07-11');
      expect((data['buckets']['5x16'] as List).length, 38);
      expect((data['buckets']['5x16'] as List).first, null); // weekend
    });
    test('get one marked forward curve, one bucket (marked)', () async {
      var res = await api.getForwardCurveForBucket(
          'isone_energy_4000_da_lmp', '5x16', '2020-07-06');
      var data = json.decode(res.result);
      expect(data['terms'].first, '2020-07-07');
      expect(data['buckets']['5x16'].first, 23.48);
    });
    test('a marked forward curve with wrong bucket returns empty', () async {
      var res = await api.getForwardCurveForBucket(
          'ng_henryhub', '5x16', '2018-03-03');
      var data = json.decode(res.result);
      expect(data.isEmpty, true);
    });
    test('get one marked forward curve, one bucket (computed)', () async {
      var res = await api.getForwardCurveForBucket(
          'isone_energy_4000_da_lmp', 'offpeak', '2020-07-06');
      var data = json.decode(res.result) as Map;
      expect(data['terms'].first, '2020-07-07'); // Tue
      expect(data['buckets']['Offpeak'].first.toStringAsFixed(2), '15.50');
      expect(data['terms'][25], '2020-08');
      expect(data['buckets']['Offpeak'][25].toStringAsFixed(5), '19.39706');
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
  });

  group('ForwardMarks client tests:', () {
    var clientFm = client.ForwardMarks(Client(), rootUrl: rootUrl);
    var location = getLocation('America/New_York');
    test('get mh curve as of 7/6/2020 for all buckets', () async {
      var curveId = 'isone_energy_4000_da_lmp';
      var res = await clientFm.getForwardCurve(curveId, Date(2020, 7, 6),
          tzLocation: location);
      expect(res[0].interval, Date(2020, 7, 7, location: location));
      expect(res.length, 42);
      var jan21 = res.observationAt(Month(2021, 1, location: location));
      expect(jan21.value[IsoNewEngland.bucket5x16], 60.7);
    });
    test('get mh hourly shape as of 5/29/2020 for all buckets', () async {
      var curveId = 'isone_energy_4000_hourlyshape';
      var hs = await clientFm.getHourlyShape(curveId, Date(2020, 5, 29),
          tzLocation: location);
      expect(hs.buckets.length, 3);
      expect(
          hs.data.first.interval.start.location.toString(), 'America/New_York');
    });
  });
}

// void repopulateDb() async {
//   var archive = ForwardMarksArchive();
//   await archive.db.open();
//   await archive.dbConfig.coll.remove(<String, dynamic>{});
//   await insertData(archive);
// //  await archive.setup();
//   await archive.db.close();
// }

/// Some data for testing.
///
void insertMarks() async {
  var archive = ForwardMarksArchive();
  await archive.db.open();
  await archive.dbConfig.coll.remove(<String, dynamic>{});
  await archive.insertData(hourlyShape20191231());
  await archive.insertData(marks20200529());
  await archive.insertData(marks20200706());
  await archive.insertData(volatilitySurface());
  await archive.db.close();
}

void main() async {
  await initializeTimeZone();

  // await insertMarks();

  await tests('http://localhost:8080/');
}
