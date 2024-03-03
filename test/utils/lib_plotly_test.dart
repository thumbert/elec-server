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

  Plotly.now(traces, layout,
      file: File('${Platform.environment['HOME']}/Downloads/test_plot.html'));
}

void test1b() {
  const traces = [
    {
      'x': [1, 2, 3, 4],
      'y': [10, 15, 13, 17],
      'mode': 'markers'
    },
  ];
  const layout = {'title': 'Scatter Plot', 'height': 650, 'width': 800};
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
  Plotly.exportJs(
    traces,
    layout,
    file: File('${Platform.environment['HOME']}/Downloads/test_plot.js'),
    eventHandlers: eventHandlers,
  );
}

void testHeatmap() {
  var traces = [
    {
      "x": [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36
      ],
      "y": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      "z": [
        [
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          2,
          3,
          4,
          5,
          6,
          7,
          7,
          8,
          9,
          9,
          8,
          7,
          6,
          5,
          4,
          3,
          3,
          5,
          5,
          5,
          5,
          7,
          7,
          7,
          5,
          5,
          5,
          7,
          7,
          7,
          7
        ],
        [
          0,
          0,
          1,
          1,
          0,
          0,
          2,
          3,
          4,
          5,
          6,
          6,
          7,
          8,
          8,
          9,
          9,
          8,
          7,
          6,
          5,
          4,
          3,
          5,
          5,
          5,
          6,
          7,
          7,
          7,
          7,
          7,
          7,
          7,
          7,
          7,
          7,
          7
        ],
        [
          0,
          0,
          0,
          1,
          1,
          2,
          3,
          4,
          5,
          6,
          6,
          7,
          7,
          8,
          9,
          9,
          8,
          7,
          7,
          6,
          6,
          5,
          4,
          5,
          5,
          5,
          6,
          6,
          7,
          7,
          7,
          7,
          7,
          7,
          7,
          8,
          7,
          7
        ],
        [
          0,
          0,
          0,
          0,
          0,
          2,
          3,
          4,
          5,
          6,
          6,
          7,
          8,
          8,
          9,
          9,
          8,
          7,
          7,
          6,
          6,
          5,
          4,
          3,
          5,
          5,
          6,
          6,
          6,
          8,
          8,
          8,
          7,
          7,
          8,
          7,
          7,
          7
        ],
        [
          1,
          1,
          0,
          0,
          0,
          2,
          3,
          4,
          5,
          6,
          7,
          7,
          7,
          8,
          9,
          9,
          9,
          8,
          7,
          6,
          5,
          5,
          4,
          2,
          4,
          4,
          6,
          6,
          6,
          8,
          8,
          8,
          8,
          8,
          8,
          7,
          7,
          7
        ],
        [
          1,
          1,
          0,
          0,
          0,
          0,
          3,
          4,
          5,
          6,
          6,
          6,
          7,
          7,
          8,
          9,
          9,
          8,
          7,
          6,
          5,
          4,
          3,
          2,
          4,
          4,
          6,
          6,
          6,
          8,
          8,
          8,
          8,
          8,
          8,
          7,
          7,
          7
        ],
        [
          2,
          1,
          1,
          1,
          1,
          0,
          2,
          3,
          4,
          5,
          6,
          6,
          7,
          7,
          8,
          9,
          8,
          7,
          7,
          6,
          5,
          4,
          2,
          2,
          4,
          4,
          4,
          6,
          6,
          8,
          8,
          8,
          8,
          8,
          7,
          7,
          7,
          7
        ],
        [
          2,
          2,
          2,
          2,
          1,
          0,
          0,
          2,
          3,
          3,
          5,
          6,
          6,
          7,
          7,
          8,
          7,
          7,
          6,
          5,
          4,
          3,
          2,
          4,
          4,
          4,
          6,
          6,
          6,
          8,
          8,
          8,
          9,
          9,
          9,
          7,
          7,
          7
        ],
        [
          2,
          2,
          2,
          2,
          1,
          0,
          0,
          1,
          1,
          2,
          3,
          5,
          6,
          6,
          7,
          7,
          7,
          6,
          5,
          4,
          3,
          2,
          2,
          4,
          4,
          4,
          6,
          6,
          8,
          8,
          8,
          8,
          7,
          7,
          7,
          7,
          7,
          7
        ],
        [
          2,
          2,
          2,
          2,
          1,
          1,
          1,
          1,
          1,
          1,
          2,
          3,
          5,
          6,
          6,
          6,
          6,
          5,
          4,
          3,
          2,
          2,
          4,
          4,
          4,
          6,
          6,
          6,
          8,
          8,
          7,
          7,
          7,
          7,
          7,
          7,
          7,
          7
        ],
        [
          3,
          3,
          2,
          2,
          2,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          3,
          5,
          5,
          5,
          5,
          3,
          3,
          2,
          2,
          2,
          4,
          4,
          6,
          6,
          6,
          8,
          8,
          8,
          8,
          8,
          8,
          7,
          7,
          7,
          8,
          8
        ],
        [
          4,
          4,
          3,
          2,
          2,
          2,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          3,
          3,
          3,
          1,
          1,
          1,
          2,
          2,
          4,
          4,
          4,
          6,
          6,
          6,
          8,
          8,
          8,
          8,
          8,
          8,
          7,
          7,
          7,
          8,
          8
        ],
        [
          5,
          4,
          3,
          3,
          2,
          2,
          2,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          2,
          2,
          4,
          4,
          4,
          6,
          6,
          6,
          6,
          6,
          8,
          8,
          6,
          8,
          8,
          7,
          7,
          7,
          7
        ]
      ],
      "type": "heatmap"
    },
    {
      "x": [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        35,
        35,
        35,
        35,
        35,
        35,
        35,
        35,
        36,
        37
      ],
      "y": [
        0,
        0,
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        6,
        7,
        8,
        9,
        10,
        10,
        10,
        10,
        9,
        8,
        7,
        6,
        5,
        4,
        3,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        12
      ],
      "mode": "lines",
      "line": {"color": "black", "width": 3}
    }
  ];
  final layout = {
    "width": 1200,
    "height": 500,
    "xaxis": {"constrain": "domain", "zeroline": false, "showline": false},
    "yaxis": {
      "scaleanchor": "x",
      "range": [-1, 13],
      "zeroline": false,
      "showline": false
    }
  };
  Plotly.now(
    traces,
    layout,
    file: File('${Platform.environment['HOME']}/Downloads/heatmap2.html'),
  );
}

void main() {
  // test1a();
  // test1b();
  testHeatmap();
}
