library test.client.forward_marks;

import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/marks/forward_marks.dart';
import 'package:elec_server/src/db/marks/forward_marks.dart';
import 'package:elec_server/src/db/marks/composite_curves.dart';
import 'package:test/test.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:timezone/standalone.dart';

/// Get the curves that are directly marked
List<String> getMarkedCurveIds() {
  return [
    'elec_isone_hub_lmp_da',
    'elec_isone_maine_lmpspread_da',
    'elec_isone_nh_lmpspread_da',
    'elec_isone_ct_lmpspread_da',
    'elec_isone_ri_lmpspread_da',
    'elec_isone_sema_lmpspread_da',
    'elec_isone_wcma_lmpspread_da',
    'elec_isone_nema_lmpspread_da',
    'elec_isone_4011_lmpspread_da',
    'elec_pjm_westernhub_lmp_da',
    ...['ng_henryhub', 'ng_algcg_gdm', 'ng_tetcom3_gdm'],
  ]..sort();
}

void insertData(ForwardMarksArchive archive) async {
  var location = getLocation('US/Eastern');
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
    if (curveId.startsWith('elec')) {
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
    if (curveId.contains('spread') &&
        day != calendar.firstBusinessDate(month0)) {
      continue;
    }
    out.add({
      'fromDate': day.toString(),
      'curveId': curveId,
      'months': months.map((e) => e.toIso8601String()).toList(),
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
      'months': months.map((e) => e.toIso8601String()).toList(),
      'buckets': {
        '7x24': List.generate(n, (i) => 2 + rand.nextDouble()),
      },
    });
  }
  return out;
}

void tests() async {
  var archive = ForwardMarksArchive();
//  group('forward marks archive tests:', () {
//    setUp(() async {
//      await archive.db.open();
////      await archive.db.dropCollection(archive.dbConfig.collectionName);
////      await insertData(archive);
////      await archive.setup();
//    });
//    tearDown(() async => await archive.db.close());
//    test('document equality', () {
//      var document = <String, dynamic>{
//        'fromDate': '2018-12-14',
//        'version': '2018-12-14T10:12:47.000-0500',
//        'curveId': 'elec_isone_4011_lmp_da',
//        'months': ['2019-01', '2019-02', '2019-12'],
//        'buckets': {
//          '5x16': [89.10, 86.25, 71.05],
//          '2x16H': [72.19, 67.12, 42.67],
//          '7x8': [44.18, 39.73, 38.56],
//        }
//      };
//      var newDocument = <String, dynamic>{
//        'fromDate': '2018-12-15',
//        'version': '2018-12-15T11:15:47.000-0500',
//        'curveId': 'elec_isone_4011_lmp_da',
//        'months': ['2019-01', '2019-02', '2019-12'],
//        'buckets': {
//          '5x16': [89.10, 86.25, 71.05],
//          '2x16H': [72.19, 67.12, 42.67],
//          '7x8': [44.18, 39.73, 38.56],
//        }
//      };
//      expect(archive.needToInsert(document, newDocument), false);
//    });
//  });

  group('forward marks api tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    var api = ForwardMarks(archive.db);
    var allCurveIds = [
      ...getMarkedCurveIds(),
      ...getCompositeCurves().map((e) => e['curveId'])
    ]..sort();
    test('api get all curveIds', () async {
      var res = await api.getCurveIds();
      expect(res, allCurveIds);
    });
    test('api get all curveIds with pattern', () async {
      var res = await api.getCurveIdsContaining('isone');
      expect(res, allCurveIds.where((e) => e.contains('isone')).toList());
    });
    test('api get all available fromDates for a curveId', () async {
      var res = await api.getFromDatesForCurveId('elec_isone_hub_lmp_da');
      expect(res.length, 255);
    });
    test('api get all available fromDates for a spread curve', () async {
      var res =
          await api.getFromDatesForCurveId('elec_isone_ct_lmpspread_da');
      expect(res.length, 12);
    });
    test('get one forward curve, all marked buckets', () async {
      var res =
          await api.getForwardCurve('elec_isone_hub_lmp_da', '2018-03-03');
      var data = json.decode(res.result) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'months', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
    });
    test('get one marked forward curve, one bucket (marked)', () async {
      var res = await api.getForwardCurveForBucket(
          'elec_isone_hub_lmp_da', '5x16', '2018-03-03');
      var data = <String, num>{...json.decode(res.result)};
      expect(data.keys.first, '2018-04');
      expect(data.values.first, 45.99158496771074);
    });
    test('a marked forward curve with wrong bucket returns empty', () async {
      var res = await api.getForwardCurveForBucket(
          'ng_henryhub', '5x16', '2018-03-03');
      var data = <String, num>{...json.decode(res.result)};
      expect(data.isEmpty, true);
    });
    test('get one marked forward curve, one bucket (computed)', () async {
      var res = await api.getForwardCurveForBucket(
          'elec_isone_hub_lmp_da', 'offpeak', '2018-03-03');
      var data = <String, num>{...json.decode(res.result)};
      expect(data.keys.first, '2018-04');
      expect(data.values.first.toStringAsFixed(5), '25.24325');
    });
    test('get values of different strips/buckets for one curve', () async {
      var res = await api.getForwardCurveForBucketsStrips(
          'elec_isone_hub_lmp_da',
          '5x16_offpeak',
          '2018-03-03',
          'Jan19-Feb19_Jul19-Aug19_Jan20-Jun20');
      var aux = json.decode(res.result) as Map;
      expect(aux.keys.toSet(), {'5x16', 'offpeak'});
      var data = aux['5x16'];
      expect(data.keys.length, 3);
      expect(data.keys.first, 'Jan19-Feb19');
      expect(data.values.first, 46.13419709530633);
    });

//    test('get values of different strips/buckets for one curve, one wrong term', () async {
//      var res = await api.getForwardCurveForBucketsStrips(
//          'elec_isone_hub_lmp_da',
//          '5x16',
//          '2018-03-03',
//          'Jan19_Jub19-Aug19_2020-01');
//      var aux = json.decode(res.result) as Map;
//      expect(aux.keys.toSet(), {'5x16'});
//      var data = aux['5x16'];
//      expect(data.keys.length, 1);
//      expect(data.keys.first, 'Jan19');
//      expect(data.values.first, 46.18917009397204);
//    });


    test('get the buckets marked for one curve', () async {
      // marked curve
      var b0 = await api.getBucketsMarked('elec_isone_hub_lmp_da');
      expect(b0, {'5x16', '2x16H', '7x8'});
      // composite curve
      var b1 = await api.getBucketsMarked('elec_isone_ct_lmp_da');
      expect(b1, {'5x16', '2x16H', '7x8'});
      // fuel curve
      var b2 = await api.getBucketsMarked('ng_henryhub');
      expect(b2, {'7x24'});
    });
  });

}

void repopulateDb() async {
  var archive = ForwardMarksArchive();
  await archive.db.open();
  await archive.db.dropCollection(archive.dbConfig.collectionName);
  await insertData(archive);
  await archive.setup();
  await archive.db.close();
}


void main() async {
  await initializeTimeZone();
  await tests();

//  await repopulateDb();

}
