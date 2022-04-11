library utils.lib_plotly;

import 'dart:convert';
import 'dart:io';

class Plotly {
  /// Create a plotly chart in the browser by writing your data into a
  /// temporary html file and launching chrome on it.
  static now(List<Map<String, dynamic>> traces, Map<String, dynamic> layout,
      {Map<String, dynamic>? config,
      bool displayLogo = false,
      File? file,
      bool cleanUp = true,
      int? width,
      int? height}) {
    Directory? dir;
    if (file == null) {
      dir = Directory.systemTemp.createTempSync();
      file = File('${dir.path}/test.html')..createSync();
    }
    config ??= {'displaylogo': false, 'responsive': true};
    if (!config.containsKey('displaylogo')) {
      config['displaylogo'] = false;
    }
    if (!config.containsKey('responsive')) {
      config['responsive'] = true;
    }

    file.writeAsStringSync(_makePage(traces, layout, config));

    /// launch chrome on the temporary file
    var res = Process.runSync('google-chrome', [file.path]);
    print(res);
    if (res.exitCode != 0) {
      print(res);
    }

    if (cleanUp) {
      if (dir != null) {
        dir.deleteSync(recursive: true);
      } else {
        file.deleteSync();
      }
    }
  }

  static String _makePage(List<Map<String, dynamic>> traces,
      Map<String, dynamic> layout, Map<String, dynamic> config) {
    // print(traces.toString());
    // print(layout.toString());
    // print(config.toString());

    var out = """ 
<!DOCTYPE html>
<html>
<head>
  <script src="https://cdn.plot.ly/plotly-2.11.1.min.js"></script>
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
