library utils.lib_plotly;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

class Plotly {
  /// Write just the plotly js script to a file.  The div id will be the file
  /// basename.  This way, you can construct your html document the way you
  /// need.
  static void exportJs(
      List<Map<String, dynamic>> traces, Map<String, dynamic> layout,
      {required File file, Map<String, dynamic>? config}) {
    if (extension(file.path) != '.js') {
      throw ArgumentError('Filename extension needs to be .js');
    }
    var name = basename(file.path);
    var divId = name.replaceAll(RegExp('\\.js\$'), '');
    config ??= {'displaylogo': false, 'responsive': true};
    file.writeAsStringSync("""
      $divId = document.getElementById("$divId");
      Plotly.newPlot( $divId, ${json.encode(traces)}, ${json.encode(layout)}, ${json.encode(config)} );
    """);
  }

  /// Create a plotly chart in the browser by writing your data into a
  /// temporary html file and launching chrome on it.
  static void now(
    List<Map<String, dynamic>> traces,
    Map<String, dynamic> layout, {
    Map<String, dynamic>? config,
    bool displayLogo = false,
    required File file,
  }) {
    config ??= {'displaylogo': false, 'responsive': true};
    if (!config.containsKey('displaylogo')) {
      config['displaylogo'] = false;
    }
    if (!config.containsKey('responsive')) {
      config['responsive'] = true;
    }
    if (extension(file.path) != '.html') {
      throw ArgumentError('Filename extension needs to be .html');
    }
    file.writeAsStringSync(_makePage(traces, layout, config));
  }

  static String _makePage(List<Map<String, dynamic>> traces,
      Map<String, dynamic> layout, Map<String, dynamic> config) {
    var out = """ 
<!DOCTYPE html>
<html>
<head>
  <script src="https://cdn.plot.ly/plotly-2.26.0.min.js" charset="utf-8"></script>
</head>
<body>
  <div id="chart"></div>
  <script>
  	div = document.getElementById("chart");
	  Plotly.newPlot( div, ${json.encode(traces)}, ${json.encode(layout)}, ${json.encode(config)} );
  </script>
</body>
</html>
""";
    return out;
  }
}
