import 'package:test/test.dart';

import 'package:elec_server/src/utils/to_csv.dart';

void tests() {
  group('to_csv tests', () {
    test('list of maps to csv, with null entries', () {
      var xs = [
        {'code': 'BWI', 'value': 75},
        {'code': 'BOS', 'value': null},
        {'code': 'BDL', 'value': 72},
      ];
      expect(listOfMapToCsv(xs), 'code,value\r\nBWI,75\r\nBOS,\r\nBDL,72');
    });
  });
}

void main() {
  tests();
}
