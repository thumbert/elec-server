import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:csv/csv.dart';
import 'package:elec_server/src/utils/lib_plotly.dart';

/// First input line is the column names
List<Map<String, dynamic>> makeTraces(List<String> inputLines,
    {String mode = 'lines', String type = 'scatter'}) {
  final converter = CsvToListConverter(
    eol: '\n',
    fieldDelimiter: ',',
    shouldParseNumbers: true,
  );
  var content = inputLines.map((e) => converter.convert(e).first).toList();
  var names = content[0].cast<String>();
  var x = <String>[];
  var series = List.generate(
    names.length - 1,
    (index) => <num>[],
  );
  for (var i = 1; i < content.length; i++) {
    var row = content[i];
    x.add(row[0].toString());
    for (var j = 1; j < row.length; j++) {
      series[j - 1].add(row[j]);
    }
  }

  var traces = <Map<String, dynamic>>[];
  for (var i = 0; i < series.length; i++) {
    traces.add({
      'x': [...x],
      'y': series[i],
      'name': names[i + 1],
      'mode': mode,
      'type': type,
    });
  }
  return traces;
}

void main(List<String> args) {
  var parser = ArgParser()
    ..addFlag('help', abbr: 'h')
    ..addFlag('version', abbr: 'v', help: 'Current qplot version.')
    ..addOption('file',
        help:
            'Html file path output.  If not specified, it will open in the current browser.')
    ..addOption('config',
        help:
            'Plotly config options as a JSON string.  For example: {"height": 800}.')
    ..addOption('mode',
        defaultsTo: 'lines',
        help:
            'Plot mode. Default is "lines". Other options are "markers", "lines+markers", "text", etc.')
    ..addOption('type',
        defaultsTo: 'scatter',
        help:
            'Plot mode. Default is "scatter". Other options are "bar", "pie", "box", etc.');

  var results = parser.parse(args);
  if (results['help']) {
    print('''
Create a quick plot from piped input data using plotly js.  Input data should 
be comma-separated rows of data with the first line as the header.  The first 
column is the x-axis data, and the remaining columns are variables plotted on 
the y-axis. 

Currently only timeseries are supported, but this restriction will be lifted 
in the future.

Flags:
--help or -h
  Display this message. 
--version or -v
  Display qplot version.
--file
  Specify the output HTML file path. If not specified, a temporary html file will 
  be created and opened in the default browser.  For example: './chart.html'.
--config
  Specify Plotly config options as a JSON string.  For example: '{"height": 800}'.  
--mode
  Specify the mode of the plot. Default is 'lines'. Other options are 'markers', 
  'lines+markers', etc.  
--type
  Specify the type of the plot. Default is 'scatter'. Other options are 'bar', 
  'box', etc.  

Example usage:
    echo "date,price
    2023-01-01,100
    2023-01-02,150
    2023-01-03,200
    2023-01-04,175
    2023-01-05,225
    " | qplot

    cat data.csv | qplot --mode=markers --type=scatter --config='{"height": 800}'  

''');
    exit(0);
  }
  if (results['version']) {
    print('0.0.1');
    exit(0);
  }
  File? file;
  if (results['file'] != null) {
    file = File(results['file'] as String);
    file.createSync(recursive: true);
  }

  final config = results['config'] != null
      ? json.decode(results['config'] as String)
      : <String, dynamic>{};
  final mode = results['mode'] as String;
  final type = results['type'] as String;

  List<String> lines = [];
  while (true) {
    String? line = stdin.readLineSync();
    if (line == null || line.isEmpty) break;
    lines.add(line);
  }

  final traces = makeTraces(lines, mode: mode, type: type);

  Plotly.now(
    traces,
    config,
    file: file,
  );
}
