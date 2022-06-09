library test.utils.parse_custom_integer_range_test;

import 'package:elec_server/src/utils/parse_custom_integer_range.dart';
import 'package:test/test.dart';

import 'package:elec_server/src/utils/to_csv.dart';

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
    test('pack integer list', () {
      expect(packIntegerList([1, 2, 3, 4, 5, 8, 11, 12, 13, 22]),
          '1-5, 8, 11-13, 22');
      expect(
          packIntegerList([1, 2, 3, 4, 5, 8, 11, 13, 14]), '1-5, 8, 11, 13-14');
    });
  });
}

void main() {
  tests();
}
