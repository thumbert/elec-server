import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/utils.dart';
import 'package:timeseries/timeseries.dart';

List<(int, num)> medianByMonth(TimeSeries<num> ts) {
  var groups = groupBy(ts, (e) => (e.interval as Month).month);
  return groups.entries.map((e) {
    var q = Quantile(e.value.map((e) => e.value).toList());
    return (e.key, q.median());
  }).toList();
}

void quebecHydroGeneration() {
  final con = Connection(getCanadianStatisticsArchive().duckDbPath);

  var quebec = con.fetchRows("""
SELECT REF_DATE as month, VALUE as MWh 
FROM electricity_production 
WHERE "Type of electricity generation" = 'Hydraulic turbine' 
AND "Class of electricity producer" = 'Total all classes of electricity producer'
AND GEO = 'Quebec'
ORDER BY month;
""", (List x) {
    return IntervalTuple<num>(Month.parse(x[0]), x[1]);
  }).toTimeSeries();

  var last12 = quebec.tail(n: 12);
  var lastTerm = Term.fromInterval(last12.domain);
  var histTerm = Term.fromInterval(
      Interval(quebec.first.interval.start, last12.first.interval.start));
  var medianValues = medianByMonth(quebec);

  var rand = Random();
  var traces = <Map<String, dynamic>>[
    {
      'x': quebec
          .take(quebec.length - 12)
          .map((e) => e.interval.start.month + 0.2 * (rand.nextDouble() - 0.5))
          .toList(),
      'y': quebec.take(quebec.length - 12).map((e) => e.value).toList(),
      'text': quebec
          .take(quebec.length - 12)
          .map((e) => (e.interval as Month).toIso8601String())
          .toList(),
      'mode': 'markers',
      'name': 'Data $histTerm'
    },
    {
      'x': quebec.tail(n: 12).map((e) => e.interval.start.month).toList(),
      'y': quebec.tail(n: 12).map((e) => e.value).toList(),
      'text': quebec
          .tail(n: 12)
          .map((e) => (e.interval as Month).toIso8601String())
          .toList(),
      'mode': 'markers',
      // 'marker': {
      //   'color': '818C78',
      // },
      'name': 'Data $lastTerm'
    },
    {
      'x': medianValues.map((e) => e.$1).toList(),
      'y': medianValues.map((e) => e.$2).toList(),
      'name': 'Median ${Term.fromInterval(quebec.domain)}',
      'mode': 'markers',
      'marker': {
        // 'symbol': 'star',
        'symbol': 17,
        'color': 'black',
      },
    },
  ];

  final layout = {
    'title': 'Hydro Generation in Quebec',
    'xaxis': {
      'title': 'Month of the year',
      'tickvals': List.generate(12, (i) => i + 1),
    },
    'yaxis': {'title': 'Monthly Energy, MWh'},
    'width': 1150,
    'height': 600,
  };
  Plotly.exportJs(
    traces,
    layout,
    file: File(
      '${Report.path}/assets/hydro_generation_quebec.js',
    ),
  );

  /// Plot historical 12 months average
  ///
  ///
  var cumMeanQuebec = TimeSeries.from(
          quebec.intervals,
          MovingStatistics(leftWindow: 11, rightWindow: 0)
              .movingMean(quebec.values.toList()))
      .skip(12)
      .toTimeSeries();
  () {
    var traces = <Map<String, dynamic>>[
      {
        'x': cumMeanQuebec
            .map((e) => (e.interval as Month).toIso8601String())
            .toList(),
        'y': cumMeanQuebec.map((e) => e.value).toList(),
        'mode': 'markers',
        'name': 'Quebec',
      },
    ];
    final layout = {
      'title': 'Hydro Generation',
      'xaxis': {
        'title': 'Month',
      },
      'yaxis': {'title': 'Rolling 12-months average, MWh'},
      'width': 1150,
      'height': 600,
    };
    Plotly.exportJs(
      traces,
      layout,
      file: File(
        '${Report.path}/assets/hydro_generation_12mth.js',
      ),
    );
  }();
}

class Report {
  static const String path =
      '/home/adrian/Documents/repos/git/thumbert/rascal/html/docs/projects/canadian_generation/web';
}

void main() {
  quebecHydroGeneration();
}
