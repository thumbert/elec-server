library test.utils.term_cache_test;

import 'package:date/date.dart';
import 'package:elec_server/utils.dart';
import 'package:test/test.dart';

tests() {
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
    test('domain test', () async {
      var cache = TermCache(loader, keyAssign);
      expect(cache.domain().isEmpty, true);
      var term1 = parseTerm('1Jan19-4Jan19');
      await cache.set(term1);
      expect(cache.domain(), [term1]);
      expect(cache.get(term1).length, 4);
    });
    test('get missing days only', () async {
      var cache = TermCache(loader, keyAssign);
      var term1 = parseTerm('1Jan19-4Jan19');
      await cache.set(term1);
      var term2 = parseTerm('8Jan19-12Jan19');
      await cache.set(term1);
      await cache.set(term2);
      expect(cache.domain(), [term1, term2]);
      await cache.set(parseTerm('3Jan19-11Jan19'));
      expect(cache.domain(), [parseTerm('1Jan19-12Jan19')]);
    });
  });
}

main() async {
  await tests();
}
