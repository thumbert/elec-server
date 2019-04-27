library test.utils.to_csv_test;

import 'package:test/test.dart';

import 'package:elec_server/src/utils/to_csv.dart';

tests() {
  group('to_csv tests', () {
    test('list of maps to csv, with null entries', () {
      var xs = [
        {'code': 'BWI', 'value': 75},
        {'code': 'BOS', 'value': null},
        {'code': 'BDL', 'value': 72},
      ];
      print(listOfMapToCsv(xs));
    });
  });
}


main() {
  tests();
}