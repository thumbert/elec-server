library test.utils.term_cache_test;

import 'package:date/date.dart';
import 'package:elec_server/utils.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

void tests() {
  group('TestCache tests:', () {
    var loader = (Interval interval) {
      var days =
          interval.splitLeft((dt) => Date.fromTZDateTime(dt)).cast<Date>();
      var out = <Map<String, dynamic>>[];
      for (var date in days) {
        out.add({
          'date': date,
          'count': date.day,
          'value': date.dayOfYear(),
        });
      }
      return Future.value(out);
    };
    var keyAssign = (Map<String, dynamic> e) => e['date'] as Date;
    var keysFromInterval = (Interval interval) =>
        interval.splitLeft((dt) => Date.fromTZDateTime(dt)).cast<Date>();

    test('domain test', () async {
      var cache = TermCache(loader, keyAssign, keysFromInterval);
      expect(cache.domain().isEmpty, true);
      var term1 = parseTerm('1Jan19-4Jan19');
      await cache.set(term1);
      expect(cache.domain(), [term1]);
      expect(cache.get(term1).length, 4);
    });

    test('get missing days only', () async {
      var cache = TermCache(loader, keyAssign, keysFromInterval);
      var term1 = parseTerm('1Jan19-4Jan19');
      await cache.set(term1);
      var term2 = parseTerm('8Jan19-12Jan19');
      await cache.set(term1);
      await cache.set(term2);
      expect(cache.domain(), [term1, term2]);
      await cache.set(parseTerm('3Jan19-11Jan19'));
      expect(cache.domain(), [parseTerm('1Jan19-12Jan19')]);
    });

    test('a monthly cache', () async {
      var loader = (Interval interval) {
        var months = interval.splitLeft((dt) => Month.fromTZDateTime(dt));
        var out = <Map<String, dynamic>>[];
        for (var month in months) {
          out.add({
            'month': month,
            'count': month.year,
            'value': month.month,
          });
        }
        return Future.value(out);
      };
      var keyAssign = (Map<String, dynamic> e) => e['month'] as Month;
      var cache = MonthCache(loader, keyAssign);
      await cache.set(parseMonth('Oct19'));
      await cache.set(parseMonth('Nov19'));
      expect(cache.domain(), [parseTerm('Oct19-Nov19')]);
    });
  });
}

void main() async {
  await tests();
}
