library test.utils.lib_plotly_test;

import 'dart:io';

import 'package:elec_server/src/utils/lib_plotly.dart';
import 'package:test/test.dart';

var page = """ 
<!DOCTYPE html>
<html>
<head>
  <script src="https://cdn.plot.ly/plotly-2.11.1.min.js"></script>
</head>
<body>
  <div id="tester"></div>
  <script>
  	TESTER = document.getElementById('tester');
	  Plotly.newPlot( TESTER, [{
	    x: [1, 2, 3, 4, 5],
	    y: [1, 2, 4, 8, 16] }], {
	    margin: { t: 0 } } );
</script>
</body>
</html>
""";


void test1a() {
  const traces = [
    {
      'x': [1, 2, 3, 4],
      'y': [10, 15, 13, 17],
      'mode': 'markers'
    },
    {
      'x': [2, 3, 4, 5],
      'y': [16, 5, 11, 10],
      'mode': 'lines'
    },
    {
      'x': [1, 2, 3, 4],
      'y': [12, 9, 15, 12],
      'mode': 'lines+markers'
    }
  ];
  const layout = {
    'title': 'Line and Scatter Plot',
    'height': 650,
    'width': 800
  };

  Plotly.now(traces, layout, file: File('${Platform.environment['HOME']}/Downloads/test_plot.html'));
}

void test1b() {
  const traces = [
    {
      'x': [1, 2, 3, 4],
      'y': [10, 15, 13, 17],
      'mode': 'markers'
    },
  ];
  const layout = {
    'title': 'Scatter Plot',
    'height': 650,
    'width': 800
  };
  Plotly.exportJs(traces, layout, file: File('${Platform.environment['HOME']}/Downloads/test_plot.js'));
}


void main() {
  // test1a();
  test1b();
}
