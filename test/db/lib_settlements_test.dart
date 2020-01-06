library test.db.lib_setlements_test;

import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void tests() {
  test('two groups', () {
    var xs = [
      {'date': '2019-01-01', 'product': 'A', 'version': 1, 'value': 1.1},
      {'date': '2019-01-01', 'product': 'B', 'version': 1, 'value': 1.2},
      {'date': '2019-01-02', 'product': 'A', 'version': 1, 'value': 2.1},
      {'date': '2019-01-02', 'product': 'B', 'version': 1, 'value': 2.2},
      {'date': '2019-01-03', 'product': 'A', 'version': 1, 'value': 3.1},
      {'date': '2019-01-03', 'product': 'B', 'version': 1, 'value': 3.2},
      {'date': '2019-01-02', 'product': 'A', 'version': 2, 'value': 4.1},
      {'date': '2019-01-02', 'product': 'B', 'version': 2, 'value': 4.2},
    ];
    var out0 = getNthSettlement2(xs,
        n: 0, group: (e) => Tuple2(e['date'], e['product']));
    expect(out0, xs.sublist(0, 6));

    var out1 = getNthSettlement2(xs,
        n: 1, group: (e) => Tuple2(e['date'], e['product']));
    expect(out1, [xs[0], xs[1], xs[6], xs[7], xs[4], xs[5]]);

    var out2 = getNthSettlement2(xs,
        n: 2, group: (e) => Tuple2(e['date'], e['product']));
    expect(out2, [xs[0], xs[1], xs[6], xs[7], xs[4], xs[5]]);
  });
}

void main() {
  tests();
}
