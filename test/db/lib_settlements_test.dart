import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void tests() {
  group('lib_settlements test', () {
    var data = <Map<String, dynamic>>[
      {'version': '1', 'date': '2018-01-01', 'value': 10},
      {'version': '1', 'date': '2018-01-02', 'value': 20},
      {'version': '1', 'date': '2018-01-03', 'value': 30},
      {'version': '2', 'date': '2018-01-01', 'value': 11},
      {'version': '2', 'date': '2018-01-02', 'value': 21},
      {'version': '2', 'date': '2018-01-03', 'value': 31},
      {'version': '3', 'date': '2018-01-01', 'value': 12},
      {'version': '3', 'date': '2018-01-02', 'value': 22},
      {'version': '3', 'date': '2018-01-03', 'value': 32},
      {'version': '4', 'date': '2018-01-02', 'value': 23},
    ];
    test('get first settlement', () {
      var res = getNthSettlement(data, (e) => e['date'], n: 0);
      expect(res.length, 3);
      expect(res, [
        {'version': '1', 'date': '2018-01-01', 'value': 10},
        {'version': '1', 'date': '2018-01-02', 'value': 20},
        {'version': '1', 'date': '2018-01-03', 'value': 30},
      ]);
    });
    test('get second settlement', () {
      var res = getNthSettlement(data, (e) => e['date'], n: 1);
      expect(res.length, 3);
      expect(res, [
        {'version': '2', 'date': '2018-01-01', 'value': 11},
        {'version': '2', 'date': '2018-01-02', 'value': 21},
        {'version': '2', 'date': '2018-01-03', 'value': 31},
      ]);
    });
    test('get last settlement', () {
      var res = getNthSettlement(data, (e) => e['date']);
      expect(res.length, 3);
      expect(res, [
        {'version': '3', 'date': '2018-01-01', 'value': 12},
        {'version': '4', 'date': '2018-01-02', 'value': 23},
        {'version': '3', 'date': '2018-01-03', 'value': 32},
      ]);
    });
    test('get all settlements', () {
      var res = getAllSettlements(data, (e) => e['date']);
      expect(res.length, 4);
      expect(res[2], [
        {'version': '3', 'date': '2018-01-01', 'value': 12},
        {'version': '3', 'date': '2018-01-02', 'value': 22},
        {'version': '3', 'date': '2018-01-03', 'value': 32},
      ]);
      expect(res[3], [
        {'version': '3', 'date': '2018-01-01', 'value': 12},
        {'version': '4', 'date': '2018-01-02', 'value': 23},
        {'version': '3', 'date': '2018-01-03', 'value': 32},
      ]);
    });

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
      var out0 =
          getNthSettlement(xs, (e) => Tuple2(e['date'], e['product']), n: 0);
      expect(out0, xs.sublist(0, 6));

      var out1 =
          getNthSettlement(xs, (e) => Tuple2(e['date'], e['product']), n: 1);
      expect(out1, [xs[0], xs[1], xs[6], xs[7], xs[4], xs[5]]);

      var out2 =
          getNthSettlement(xs, (e) => Tuple2(e['date'], e['product']), n: 2);
      expect(out2, [xs[0], xs[1], xs[6], xs[7], xs[4], xs[5]]);
    });

    test('two groups not ordered, maintains original order', () {
      var xs = [
        {'date': '2019-01-02', 'product': 'A', 'version': 1, 'value': 2.1},
        {'date': '2019-01-02', 'product': 'B', 'version': 1, 'value': 2.2},
        {'date': '2019-01-03', 'product': 'A', 'version': 1, 'value': 3.1},
        {'date': '2019-01-03', 'product': 'B', 'version': 1, 'value': 3.2},
        {'date': '2019-01-02', 'product': 'A', 'version': 2, 'value': 4.1},
        {'date': '2019-01-02', 'product': 'B', 'version': 2, 'value': 4.2},
        {'date': '2019-01-01', 'product': 'A', 'version': 1, 'value': 1.1},
        {'date': '2019-01-01', 'product': 'B', 'version': 1, 'value': 1.2},
      ];
      var out0 =
          getNthSettlement(xs, (e) => Tuple2(e['product'], e['date']), n: 0);
      expect(out0, [xs[0], xs[1], xs[2], xs[3], xs[6], xs[7]]);

      var out1 =
          getNthSettlement(xs, (e) => Tuple2(e['date'], e['product']), n: 1);
      expect(out1, [xs[4], xs[5], xs[2], xs[3], xs[6], xs[7]]);

      var out2 =
          getNthSettlement(xs, (e) => Tuple2(e['date'], e['product']), n: 2);
      expect(out2, [xs[4], xs[5], xs[2], xs[3], xs[6], xs[7]]);
    });
  });
}

void main() {
  tests();
}
