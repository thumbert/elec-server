library test.client.forward_marks;

import 'dart:convert';
import 'dart:math';
import 'package:date/date.dart';
import 'package:elec_server/api/marks/forward_marks.dart';
import 'package:elec_server/src/db/marks/forward_marks.dart';
import 'package:test/test.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:timezone/standalone.dart';


/// Get the composite/derived curves
List<Map<String,dynamic>> getCompositeCurves() {
  var entries = <Map<String,dynamic>>[
    {
      'curveId': 'elec|iso:ne|zone:maine|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:maine|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:nh|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:nh|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:ct|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:ct|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:ri|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:ri|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:sema|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:sema|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:nema|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:nema|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|ptid:4011|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|ptid:4011|spread|da'],
    },
  ];
  return entries;
}

/// Get the curves that are directly marked
List<String> getMarkedCurveIds() {
  return [
    'elec|iso:ne|hub|lmp|da',
    'elec|iso:ne|zone:maine|spread|da',
    'elec|iso:ne|zone:nh|spread|da',
    'elec|iso:ne|zone:ct|spread|da',
    'elec|iso:ne|zone:ri|spread|da',
    'elec|iso:ne|zone:sema|spread|da',
    'elec|iso:ne|zone:wcma|spread|da',
    'elec|iso:ne|zone:nema|spread|da',
    'elec|iso:ne|ptid:4011|spread|da',

    'elec|iso:pjm|hub:western hub|lmp|da',

    ...['ng;henryhub','ng;algcg;gdm', 'ng;tetcom3;gdm'],
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

  /// insert the rules for the composite/derived curves
  await archive.dbConfig.coll.insertAll(getCompositeCurves());
}

/// Generate forward curve data for one curve for a list of days.  Random data.
/// Spread curves only get marked on the first day of the month.
List<Map<String,dynamic>> _generateDataElecCurve(String curveId, List<Date> days,
    Month endMonth, Random rand) {
  var out = <Map<String,dynamic>>[];
  var multiplier = curveId.contains('spread') ? 0.05 : 1.0;
  var calendar = NercCalendar();
  for (var day in days) {
    var month0 = Month(day.year, day.month, location: day.location);
    var months = month0.next.upTo(endMonth);
    var n = months.length;
    if (curveId.contains('spread') && day != calendar.firstBusinessDate(month0)) {
      continue;
    }
    out.add({
      'fromDate': day.toString(),
      'curveId': curveId,
      'months': months.map((e) => e.toIso8601String()).toList(),
      'buckets': {
        '5x16': List.generate(n, (i) => 45*multiplier + 2*rand.nextDouble()),
        '2x16H': List.generate(n, (i) => 33*multiplier + 2*rand.nextDouble()),
        '7x8': List.generate(n, (i) => 20*multiplier + 2*rand.nextDouble()),
      }
    });
  }
  return out;
}

List<Map<String,dynamic>> _generateDataNgCurve(String curveId, List<Date> days,
    Month endMonth, Random rand) {
  var out = <Map<String,dynamic>>[];
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
  group('forward marks archive tests:', () {
    var archive = ForwardMarksArchive();

    var api = ForwardMarks(archive.db);
    setUp(() async {
      await archive.db.open();
//      await archive.db.dropCollection(archive.dbConfig.collectionName);
//      await insertData(archive);
//      await archive.setup();
    });
    tearDown(() async => await archive.db.close());
    var allCurveIds = [
      ...getMarkedCurveIds(),
      ...getCompositeCurves().map((e) => e['curveId'])
    ]..sort();
    test('api get all curveIds', () async {
      var res = await api.getCurveIds();
      expect(res, allCurveIds);
    });
    test('api get all curveIds with pattern', () async {
      var res = await api.getCurveIdsContaining('iso:ne');
      expect(res, allCurveIds.where((e) => e.contains('iso:ne')).toList());
    });
    test('api get all available fromDates for a curveId', () async {
      var res = await api.getFromDatesForCurveId('elec|iso:ne|hub|lmp|da');
      expect(res.length, 255);
    });
    test('api get all available fromDates for a spread curve', () async {
      var res = await api.getFromDatesForCurveId('elec|iso:ne|zone:ct|spread|da');
      expect(res.length, 12);
    });
    test('get one forward curve, all buckets', () async {
      var res = await api.getForwardCurve('2018-03-03',
          'elec|iso:ne|hub|lmp|da');
      var data = json.decode(res.result) as Map<String,dynamic>;
      expect(data.keys.toSet(), {'months', 'buckets'});
      expect((data['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
    });
    test('get one forward curve, one bucket', () async {
      var res = await api.getForwardCurveForBucket('2018-03-03',
          'elec|iso:ne|hub|lmp|da', '5x16');
      var data = <String,num>{...json.decode(res.result)};
      expect(data.keys.first, '2018-04');
      expect(data.values.first, 45.58681342997034);
    });
    test('get values of different strips for one curve/bucket', () async {
      var res = await api.getForwardCurveForBucketStrips('2018-03-03',
          'elec|iso:ne|hub|lmp|da', '5x16', 'Jan19-Feb19;Jul19-Aug19;Jan20-Jun20');
      var data = <String,num>{...json.decode(res.result)};
      expect(data.keys.length, 3);
      expect(data.keys.first, 'Jan19-Feb19');
      expect(data.values.first, 46.62231110069041);
    });
    test('get buckets marked', () async {
      // marked curve
      var b0 = await api.getBucketsMarked('elec|iso:ne|hub|lmp|da');
      expect(b0, {'5x16', '2x16H', '7x8'});
      // composite curve
      var b1 = await api.getBucketsMarked('elec|iso:ne|zone:ct|lmp|da');
      expect(b1, {'5x16', '2x16H', '7x8'});
      // fuel curve
      var b2 = await api.getBucketsMarked('ng;henryhub');
      expect(b2, {'7x24'});
    });


//    test('check for a spread curve the price for a day inside the month', () async {
//      var res305 = await api.getForwardCurveForBucket('2018-03-03',
//          'elec|iso:ne|zone:ct|spread|da', '5x16');
//      var res301 = await api.getForwardCurveForBucket('2018-03-01',
//          'elec|iso:ne|zone:ct|spread|da', '5x16');
//      expect(res301.length, 12);
//    });



//    test('api get one curve', () async {
//      var res = await api.forwardCurve('2018-01-07', '');
//      var c1 = json.decode(res.result);
//      expect(1, 1);
//    });
  });
}


void main() async {
  await initializeTimeZone();
  await tests();
}