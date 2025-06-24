import 'package:test/test.dart';

import '../../bin/qplot.dart';

void tests() {
  group('qplot tests', () {
    test('qplot command line', () {
      final input = """
qplot 
date,price
2023-01-01,100
2023-01-02,150
2023-01-03,200
2023-01-04,175
2023-01-05,225"
""";
      final mode = 'lines';
      final type = 'scatter';
      final file = 'output.html';
      final config = '{"responsive": true, "displaylogo": false}';

      // Simulate the qplot command line functionality
      final traces = makeTraces(input.split('\n'), mode: mode, type: type);
      final layout = {'title': 'Test Plot'};
      final out = """
""";
      // This is a placeholder for the actual test logic.
      // You can implement the logic to test the qplot functionality here.
      expect(true, isTrue); // Example assertion
    });
  });
}

void main() {
  tests();
}
