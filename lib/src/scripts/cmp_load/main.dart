import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:elec/time.dart';
import 'package:elec_server/client/utilities/cmp/cmp.dart';
import 'package:elec_server/utils.dart';
import 'package:path/path.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:html_template/html_template.dart';

part 'main.g.dart';

class _Analysis {
  final dir = '${Platform.environment['HOME']}/Downloads/Archive/Analysis/CMP';
  late final TimeSeries<num> hLoad;
  final location = IsoNewEngland.location;

  Future<void> getLoad() async {
    final client = Cmp(rootUrl: dotenv.env['ROOT_URL']!);
    final term = Term.parse('Jan20-Jul23', IsoNewEngland.location);
    hLoad = await client.getHourlyLoad(
        term, CmpCustomerClass.residentialAndSmallCommercial);
  }

  Future<void> makeShapePlots() async {
    var years = [2020, 2021, 2022, 2023];
    // print(checkMissingHours(hLoad).map((e) => e.toString()).join('\n'));
    // print(hLoad.toMonthly(sum));

    var allTerms = {
      'Jan-Feb':
          Term.generate(years: years, monthRange: (1, 2), location: location),
      'Mar':
          Term.generate(years: years, monthRange: (3, 3), location: location),
      'Apr-May':
          Term.generate(years: years, monthRange: (4, 5), location: location),
      'Jun':
          Term.generate(years: years, monthRange: (6, 6), location: location),
      'Jul':
          Term.generate(years: years, monthRange: (7, 7), location: location),
    };

    for (var key in allTerms.keys) {
      var terms = allTerms[key]!;

      /// get the days for each term
      var groups = Map.fromEntries(terms.map((term) {
        var days =
            term.days().where((e) => Calendar.nerc.isBusinessDate(e)).toSet();
        return MapEntry(term, days);
      }));

      /// big plot with shapes for each year individually
      var traces = makeShapeTraces(groups: groups, bucket: Bucket.atc);
      var layout = {
        'title': key,
        'width': 900,
        'height': terms.length * 550,
        'xaxis': {
          'title': 'Hour beginning',
        },
        'yaxis': {
          'title': 'Load shape, %',
        },
        'grid': {
          'rows': terms.length,
          'columns': 1,
          'pattern': 'independent',
          'roworder': 'bottom to top',
        }
      };
      var div = 'shape_${key.toLowerCase().replaceAll('-', '')}';
      var eventHandler = """
    // when the mouse is over a point, change the color of the trace to orange
    // except when you are a point on the median shape!
    $div.on('plotly_hover', function(data) {
      let traceNumber = data.points[0].curveNumber;
      if (traceNumber < ${div}_traces.length-1) {
        ${div}_traces[traceNumber]['line'] = {'color': '#ff9900', 'width': 4};
        let trace = ${div}_traces[traceNumber];
        // remove this trace from the array of traces
        ${div}_traces.splice(traceNumber, 1);
        // add it to the end so it sits on top of all other traces
        ${div}_traces.splice(${div}_traces.length-2, 0, trace);
        // use Plotly.react vs Plotly.restyle because it gives me access to the traces
        Plotly.react($div, ${div}_traces, ${div}_layout);
      }
    });
    // revert back to the original color and width
    $div.on('plotly_unhover', function(data){
      let traceNumber = data.points[0].curveNumber;
      if (traceNumber < ${div}_traces.length-1) {
        // have to revert both the original hover line and the last added line, otherwise will leave a mark
        ${div}_traces[traceNumber]['line'] = {'color': '#b0b0b0', 'width': 1};
        ${div}_traces[${div}_traces.length-2]['line'] = {'color': '#b0b0b0', 'width': 1};
        Plotly.react($div, ${div}_traces, ${div}_layout);
      }
    });    
    """;
      Plotly.exportJs(
        traces,
        layout,
        file: File('$dir/$div.js'),
        eventHandlers: eventHandler,
      );

      ///
      ///
      /// just the median shapes
      var traces2 = traces
          .where((e) => (e['name'] as String).startsWith('median'))
          .map((e) {
        e.remove('line');
        e.remove('xaxis');
        e.remove('yaxis');
        return e;
      }).toList();
      var layout2 = {
        'title': key,
        'width': 650,
        'height': 500,
        'xaxis': {
          'title': 'Hour beginning',
        },
        'yaxis': {
          'title': 'Load shape, %',
        },
      };
      Plotly.exportJs(
        traces2,
        layout2,
        file: File(
            '$dir/median_shape_${key.toLowerCase().replaceAll('-', '')}.js'),
      );
    }
  }

  List<Map<String, dynamic>> makeShapeTraces(
      {required Map<Term, Set<Date>> groups, required Bucket bucket}) {
    var out = <Map<String, dynamic>>[];
    var aux = groupBy(hLoad, (e) => Date.containing(e.interval.start));
    final dailyGroups = aux
        .map((key, value) => MapEntry(key, value.map((f) => f.value).toList()));

    /// group them by year to see year over year changes
    var terms = groups.keys.toList();
    for (var i = 0; i < terms.length; i++) {
      var vs = [
        ...groups[terms[i]]!.map((date) => MapEntry(date, dailyGroups[date]!))
      ];
      for (final v in vs) {
        var avg = v.value.mean();
        var weights = v.value.map((e) => e / avg).toList();
        out.add({
          'x': List.generate(v.value.length, (i) => i),
          'y': weights,
          'date': v.key.toString(),
          'mode': 'lines',
          'name': '${v.key}',
          'marker': {
            'color': '#b0b0b0',
          },
          'xaxis': 'x${v.key.year - 2019}',
          'yaxis': 'y${v.key.year - 2019}',
          'showlegend': false,
        });
      }

      /// calculate the median
      var summary = <num>[];
      for (var hour = 0; hour < 24; hour++) {
        var xs = <num>[];
        for (var i = 0; i < vs.length; i++) {
          if (vs[i].value.length == 23) {
            continue;
          }
          xs.add(vs[i].value[hour]);
        }
        var quantile = Quantile(xs);
        summary.add(quantile.median());
      }
      var meanSummary = mean(summary);
      var summaryWeight = summary.map((e) => e / meanSummary).toList();
      out.add({
        'x': List.generate(24, (i) => i),
        'y': summaryWeight,
        'mode': 'lines',
        'name': 'median ${terms[i].startDate.year}',
        'line': {
          'color': '#663399',
          'width': 4,
        },
        'xaxis': 'x${terms[i].startDate.year - 2019}',
        'yaxis': 'y${terms[i].startDate.year - 2019}',
        // 'showlegend': false,
      });
    }

    return out;
  }

  void makeReport() {
    makeShapePlots();

    var html = pageTemplate(this);
    File('$dir/index.html').writeAsStringSync(html.toString());
  }

  String getTable() {
    var tbl = '''
<table>
  <tr>
  <td>Emil</td>
  <td>Tobias</td>
  <td>Linus</td>
  </tr>
</table>
''';
    return tbl;
  }

}

@template
void _pageTemplate(_Analysis analysis) {
  // final scripts = Directory(analysis.dir).listSync().where((e) => e.path.endsWith('.js'))
  //     .map((e) => basename(e.path))
  //     .toList();
  final scripts = [
    'median_shape_janfeb.js',
    'median_shape_mar.js',
    'median_shape_aprmay.js',
    'median_shape_jun.js',
    'median_shape_jul.js',
    'shape_aprmay.js',
  ];
  var script = '';
    '''
<!doctype html>
<html>
  <head>
    <title>Maine solar</title>
    <script src="https://cdn.plot.ly/plotly-2.26.0.min.js" charset="utf-8"></script>
    <script *for="$script in $scripts" src="$script" async></script>
  </head>
  <style>
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
  </style>
  <body style="font-family:Arial">
    <h1>Solar development in Maine</h1>
    <h3>Residential and small commercial hourly load shape</h3>
    
    <p>Median shapes year over year
    <div class="flex-container">
      <div id="median_shape_janfeb"></div>
      <div id="median_shape_mar"></div>
    </div>  
    <div class="flex-container">
      <div id="median_shape_aprmay"></div>
      <div id="median_shape_jun"></div>
    </div>  
    <div class="flex-container">
      <div id="median_shape_jul"></div>
    </div>  

    <p>Individual year
    <div id="shape_aprmay"></div>

    
    ${TrustedHtml(analysis.getTable())}

    
    Comparison of median hourly load shape year over year
    <div id="solar_project_count"></div>    
  </body>
</html>
  ''';
}




Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  var analysis = _Analysis();
  await analysis.getLoad();
  analysis.makeReport();
}


// ''';
// for (var s in scripts) {
//   '<script src="$s" async></script>\n';
// }
// '''
