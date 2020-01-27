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
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:maine|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:nh|lmp|da',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:nh|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:ct|lmp|da',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:ct|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:ri|lmp|da',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:ri|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:sema|lmp|da',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:sema|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:nema|lmp|da',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:nema|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|ptid:4011|lmp|da',
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
      'asOfDate': day.toString(),
      'curveId': curveId,
      'months': months.map((e) => e.toIso8601String()).toList(),
      '5x16': List.generate(n, (i) => 45*multiplier + 2*rand.nextDouble()),
      '2x16H': List.generate(n, (i) => 33*multiplier + 2*rand.nextDouble()),
      '7x8': List.generate(n, (i) => 20*multiplier + 2*rand.nextDouble()),
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
      'asOfDate': day.toString(),
      'curveId': curveId,
      'months': months.map((e) => e.toIso8601String()).toList(),
      '7x24': List.generate(n, (i) => 2 + rand.nextDouble()),
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
    test('api get all available asOfDates', () async {
      var res = await api.getAsOfDates();
      expect(res.length, 255);
    });
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