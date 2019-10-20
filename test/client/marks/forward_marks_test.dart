library test.client.forward_marks;

import 'dart:math';
import 'package:date/date.dart';
import 'package:elec_server/api/marks/forward_marks.dart';
import 'package:elec_server/src/db/marks/forward_marks.dart';
import 'package:test/test.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:timezone/standalone.dart';

/// Generate forward curve data for one curve between two dates.  Random data.
List<Map<String,dynamic>> _generateData(String curveId, Date start, Date end,
    Month endMonth) {
  var calendar = NercCalendar();
  var days = Interval(start.start, end.end)
      .splitLeft((dt) => Date.fromTZDateTime(dt))
      .where((date) => !(date as Date).isWeekend())
      .where((date) => !calendar.isHoliday(date))
      .cast<Date>();
  var rand = Random();

  var out = <Map<String,dynamic>>[];
  for (var day in days) {
    var month0 = Month(day.year, day.month, location: day.location);
    var months = month0.next.upTo(endMonth);
    var n = months.length;
    out.add({
      'asOfDate': day.toString(),
      'curveId': curveId,
      'months': months.map((e) => e.toIso8601String()).toList(),
      '5x16': List.generate(n, (i) => 45 + 2*rand.nextDouble()),
      '2x16H': List.generate(n, (i) => 33 + 2*rand.nextDouble()),
      '7x8': List.generate(n, (i) => 20 + 2*rand.nextDouble()),
    });
  }
  return out;
}

insertData(ForwardMarksArchive archive) async {
  var n = 10;
  var location = getLocation('US/Eastern');
  var start = Date(2017, 1, 1, location: location);
  var end = Date(2018, 12, 31, location: location);
  var endMonth = Month(2025, 12, location: location);
  for (var i = 0; i < n; i++) {
    var data = _generateData('curve:$i', start, end, endMonth);
    await archive.insertData(data);
  }
}

tests() async {
  group('forward marks archive tests:', () {
    var archive = ForwardMarksArchive();
    setUp(() async {
      await archive.db.open();
      await insertData(archive);
    });
    tearDown(() async => await archive.db.close());
    test('get one curve', () async {
      expect(1, 1);
    });
  });
}


main() async {
  await initializeTimeZone();
  await tests();
}