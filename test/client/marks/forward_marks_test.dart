library test.client.forward_marks;

import 'package:date/date.dart';
import 'package:elec_server/src/db/marks/forward_marks.dart';
import 'package:test/test.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:timezone/standalone.dart';

/// Generate some forward curve data.
List<Map<String,dynamic>> _generateData(String curveId, Date start, Date end,
    int seed, Month endMonth, {List<num> monthlyWeights}) {
  var calendar = NercCalendar();
  var days = Interval(start.start, end.end)
      .splitLeft((dt) => Date.fromTZDateTime(dt))
      .where((date) => !calendar.isHoliday(date));

  var out = <Map<String,dynamic>>{};
  for (var day in days) {
//    var months = Month.
//    out.add({
//      'asOfDate': day.toString(),
//      'curveId': curveId,
//      'months':
//    });
  }

}

//insertData() async {
//  var d20191011 = {
//    'asOfDate': '2019-10-11',
//    'curveId': 'iso:ISONE;ptid:4000',
//    ''
//  };
//}

tests() async {
  group('forward marks archive tests:', () {
    var archive = ForwardMarksArchive();
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
  });
}


main() async {
  await initializeTimeZone();
  tests();
}