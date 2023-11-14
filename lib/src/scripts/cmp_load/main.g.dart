// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// TemplateGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore
// ignore_for_file: unused_local_variable
// ignore_for_file: unnecessary_string_interpolations
@GenerateFor(_pageTemplate)
TrustedHtml pageTemplate(_Analysis analysis) {
  var $ = StringBuffer();

  final scripts = [
    'median_shape_janfeb.js',
    'median_shape_mar.js',
    'median_shape_aprmay.js',
    'median_shape_jun.js',
    'median_shape_jul.js',
    'shape_aprmay.js'
  ];
  var script = '';
  $.writeln('<!DOCTYPE html>');
  $.write('<html>');
  $.write('<head>');
  $.write('\n    ');
  $.write('<title>');
  $.write('Maine solar');
  $.write('</title>');
  $.write('\n    ');
  $.write(
      '<script src="https://cdn.plot.ly/plotly-2.26.0.min.js" charset="utf-8">');
  $.write('</script>');
  $.write('\n    ');
  for (var script in template.nonNullIterable(scripts)) {
    $.write('<script src="${TrustedHtml.escape.attribute(script)}" async="">');
    $.write('</script>');
  }
  $.write('\n  ');
  $.write('<style>');
  $.write('''
    table {
      font-family: arial, sans-serif;
      border-collapse: collapse;
      width: 100%;
    }
    td, th {
      border: 1px solid #dddddd;
      text-align: left;
      padding: 8px;
    }
    tr:nth-child(even) {
      background-color: #dddddd;
    }
    .flex-container {
      display: flex;
    }

    .flex-child {
      flex: 1;
      border: 2px solid yellow;
    }  
    
    .flex-child:first-child {
      margin-right: 20px;
    } 
  ''');
  $.write('</style>');
  $.write('</head>');
  $.write('\n  \n  ');
  $.write('<body style="font-family:Arial">');
  $.write('\n    ');
  $.write('<h1>');
  $.write('Solar development in Maine');
  $.write('</h1>');
  $.write('\n    ');
  $.write('<h3>');
  $.write('Residential and small commercial hourly load shape');
  $.write('</h3>');
  $.write('\n    \n    ');
  $.write('<p>');
  $.write('''Median shapes year over year
    ''');
  $.write('</p>');
  $.write('<div class="flex-container">');
  $.write('\n      ');
  $.write('<div id="median_shape_janfeb">');
  $.write('</div>');
  $.write('\n      ');
  $.write('<div id="median_shape_mar">');
  $.write('</div>');
  $.write('\n    ');
  $.write('</div>');
  $.write('  \n    ');
  $.write('<div class="flex-container">');
  $.write('\n      ');
  $.write('<div id="median_shape_aprmay">');
  $.write('</div>');
  $.write('\n      ');
  $.write('<div id="median_shape_jun">');
  $.write('</div>');
  $.write('\n    ');
  $.write('</div>');
  $.write('  \n    ');
  $.write('<div class="flex-container">');
  $.write('\n      ');
  $.write('<div id="median_shape_jul">');
  $.write('</div>');
  $.write('\n    ');
  $.write('</div>');
  $.write('  \n\n    ');
  $.write('<p>');
  $.write('''Individual year
    ''');
  $.write('</p>');
  $.write('<div id="shape_aprmay">');
  $.write('</div>');
  $.write('''

    
    ${TrustedHtml.escape(TrustedHtml(analysis.getTable()))}

    
    Comparison of median hourly load shape year over year
    ''');
  $.write('<div id="solar_project_count">');
  $.write('</div>');
  $.write('    \n  \n\n  ');
  $.write('</body>');
  $.write('</html>');

  return TrustedHtml($.toString());
}
