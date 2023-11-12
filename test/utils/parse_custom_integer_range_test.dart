library test.utils.parse_custom_integer_range_test;

import 'package:elec_server/src/utils/parse_custom_integer_range.dart';
import 'package:test/test.dart';


void tests() {
  group('parseCustomIntegerRange tests', () {
    test('parse "1-5, 8, 11-13, 22"', () {
      var xs = unpackIntegerList('1-5, 8, 11-13, 22');
      expect(xs, [1, 2, 3, 4, 5, 8, 11, 12, 13, 22]);
    });
    test('parse empty string into an empty list', () {
      expect(unpackIntegerList(''), <int>[]);
    });
    test('parse single number into a one element list', () {
      expect(unpackIntegerList('8'), <int>[8]);
    });
    test('unpack integer range with min,max', () {
      expect(unpackIntegerRange('11-3', minValue: 1, maxValue: 12),
          [11, 12, 1, 2, 3]);
    });
    test('parse "11-3, 5-6, 9" with min max', () {
      expect(unpackIntegerList('11-3, 5-6, 9', minValue: 1, maxValue: 12),
          [11, 12, 1, 2, 3, 5, 6, 9]);
    });
    test('pack an integer list, no wrapping', () {
      expect(packIntegerList([1, 2, 3, 4, 5, 8, 11, 12, 13, 22]),
          '1-5, 8, 11-13, 22');
      expect(
          packIntegerList([1, 2, 3, 4, 5, 8, 11, 13, 14]), '1-5, 8, 11, 13-14');
    });
    test('pack an integer list with min, max', () {
      expect(
          packIntegerList([11, 12, 1, 2, 3, 6, 8, 9],
              minValue: 1, maxValue: 12),
          '11-3, 6, 8-9');
    });
  });
}

void main() {
  tests();
}
