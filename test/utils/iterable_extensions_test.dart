library test.elec.iso_parsetime;

import 'package:elec_server/utils.dart';
import 'package:test/test.dart';

void tests() {
  test('Partition an iterable', () {
    var xs = [1, 2, 3, 4, 5, 6, 7];
    var (left,right) = xs.partition((e) => e % 3 == 0);
    expect(left, [3, 6]);
    expect(right, [1, 2, 4, 5, 7]);
  });
}

void main() async {
  tests();
}
