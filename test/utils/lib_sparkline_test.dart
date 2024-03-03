library test.utils.lib_plotly_test;

import 'dart:io';

import 'package:elec_server/src/utils/lib_sparkline.dart';
import 'package:table/table_base.dart';
// import 'package:test/test.dart';

void test1() {
  final x = List.generate(10, (i) => i);
  final y = [1, 0, 5, 4, 8, 10, 15, 10, 5, 4];
  var svg = Sparkline(x, y).toSvg();
  File('${Platform.environment['HOME']}/Downloads/sparkline1.svg')
      .writeAsStringSync(svg);

  /// use it in an html table
  final data = Table.from([
    {
      'location': 'BWI',
      'T max': 85,
      'temperature': Sparkline(x, [71, 70, 75, 74, 78, 80, 85, 80, 75, 74])
          .toSvg(width: 300, height: 50),
    },
    {
      'location': 'BOS',
      'T max': 82,
      'temperature': Sparkline(x, [64, 62, 65, 67, 65, 82, 80, 75, 69, 72])
          .toSvg(width: 300, height: 50),
    },
  ]);
  var html = """
<html>
<body>
${data.toHtml()}
</body>
</html>
""";
  File('${Platform.environment['HOME']}/Downloads/sparkline1.html')
      .writeAsStringSync(html);


//   expect(svg, """
// <svg height="180px" width="500px" viewBox="0 0 9 15" preserveAspectRatio="none">
//   <path
//     d="M 0 14 L 1 15 L 2 10 L 3 11 L 4 7 L 5 5 L 6 0 L 7 5 L 8 10 L 9 11 L 9 15 L 0 15 Z"
//     stroke="transparent" fill="lightblue"
//   />
//   <path
//     d="M 0 14 L 1 15 L 2 10 L 3 11 L 4 7 L 5 5 L 6 0 L 7 5 L 8 10 L 9 11"
//     stroke-width="2" stroke="dodgerblue" fill="transparent" vector-effect="non-scaling-stroke"
//   />
// </svg>
// """);
}

void main() {
  test1();

  // test1b();
}
