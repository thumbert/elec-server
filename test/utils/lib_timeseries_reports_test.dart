library test.utils.lib_timeseries_reports_test;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void reportChangesTimeSeries() {
  var term = Term.parse('1Aug22-18Nov22', UTC);
  var ts = TimeSeries.fill(term.days(), 100.0);

  var id = ts.indexOfInterval(Date.utc(2022, 8, 31));
  ts[id] = IntervalTuple(Date.utc(2022, 8, 31), 831);

  id = ts.indexOfInterval(Date.utc(2022, 9, 30));
  ts[id] = IntervalTuple(Date.utc(2022, 9, 30), 930);

  id = ts.indexOfInterval(Date.utc(2022, 10, 31));
  ts[id] = IntervalTuple(Date.utc(2022, 10, 31), 1031);

  id = ts.indexOfInterval(Date.utc(2022, 11, 17));
  ts[id] = IntervalTuple(Date.utc(2022, 11, 17), 1117);

  id = ts.indexOfInterval(Date.utc(2022, 11, 18));
  ts[id] = IntervalTuple(Date.utc(2022, 11, 18), 1118);

  var fromTo = [
    {
      'label': '17Nov -> 18Nov',
      'from': Date.utc(2022, 11, 17),
      'to': Date.utc(2022, 11, 18),
    },
    {
      'label': '1Nov -> 18Nov',
      'from': Date.utc(2022, 11, 1),
      'to': Date.utc(2022, 11, 18),
    },
    {
      'label': 'Oct22',
      'from': Date.utc(2022, 10, 1),
      'to': Date.utc(2022, 10, 31),
    },
  ];

  var out = fromTo.map((e) => {
        ...e,
        ...ts.apply2(
            e['from'] as Interval,
            e['to'] as Interval,
            (num x1, num x2) => {
                  'change': x2 - x1,
                  'relative change': (x2 - x1) / x1,
                })
      });

  out.forEach(print);
}

Future<void> main() async {
  initializeTimeZones();
  reportChangesTimeSeries();
}
