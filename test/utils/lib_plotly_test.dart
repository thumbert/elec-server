library test.utils.lib_plotly_test;

import 'dart:io';

import 'package:elec_server/src/utils/lib_plotly.dart';

/// Example of an html document with plotly
final page = """ 
<!DOCTYPE html>
<html>
<head>
  <script src="https://cdn.plot.ly/plotly-2.26.0.min.js"></script>
</head>
<body>
  <div id="chart1"></div>
  <div id="chart2"></div>
  <script>
  	let chart1 = document.getElementById('chart1');
	  Plotly.newPlot(chart, [{
	    x: [1, 2, 3, 4, 5],
	    y: [1, 2, 4, 8, 16] }], {
	    margin: { t: 0 } } );
  </script>
  <script src="chart2.js" charset="utf-8"></script>
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
  // change the point color on hover
  const eventHandlers = """
  test_plot.on('plotly_hover', function(data){
    let traceNumber = data.points[0].curveNumber;
    let update = {'marker': {'color': '#ff9900', 'size': 12}};
    Plotly.restyle('test_plot', update, [traceNumber]);
  });
  test_plot.on('plotly_unhover', function(data){
    let traceNumber = data.points[0].curveNumber;
    let update = {'marker': {}};
    Plotly.restyle('test_plot', update, [traceNumber]);
  });  
  """;
  Plotly.exportJs(traces, layout,
      file: File('${Platform.environment['HOME']}/Downloads/test_plot.js'),
    eventHandlers: eventHandlers,
  );
}


void main() {
  // test1a();
  test1b();
}
