import 'package:date/date.dart';
import 'package:web/web.dart' as web;
import 'package:collection/collection.dart';
import 'package:dama/stat/descriptive/summary.dart';
import 'package:plotly_dart/plotly_dart.dart';
import 'package:timeseries/timeseries.dart';

/// Show the last 21 days and how they compare with the history
/// 
Plotly makeRecentDataChart(web.HTMLDivElement container, TimeSeries<num> ts) {
  final lastDay = Date.containing(ts.last.interval.start);
  final start = lastDay.subtract(21).start;
  final data = ts.window(Interval(start, lastDay.end));

  final traces = <Map<String, dynamic>>[];
  traces.add({
    'x': data.map((e) => e.interval.start.toIso8601String()).toList(),
    'y': data.map((e) => e.value).toList(),
    'type': 'scatter',
    'mode': 'lines+markers',
    'name': 'Hourly',
  });

  final layout = <String, dynamic>{
    'title': {'text': 'Hourly Hydro Generation from Hydro Quebec'},
    'yaxis': {
      'title': {'text': 'Hourly average, MW'},
    },
    'height': 600,
    // 'width': 1200,
  };

  return Plotly(
    container: container,
    divId: 'hourly-chart',
    traces: traces,
    layout: layout,
  );
}


Plotly makeHourlyChart(web.HTMLDivElement container, TimeSeries<num> ts) {
  final traces = <Map<String, dynamic>>[];
  traces.add({
    'x': ts.map((e) => e.interval.start.toIso8601String()).toList(),
    'y': ts.map((e) => e.value).toList(),
    'type': 'scatter',
    'mode': 'lines+markers',
    'name': 'Hourly',
  });

  final layout = <String, dynamic>{
    'title': {'text': 'Hourly Hydro Generation from Hydro Quebec'},
    'yaxis': {
      'title': {'text': 'Hourly average, MW'},
    },
    'height': 600,
    // 'width': 1200,
  };

  return Plotly(
    container: container,
    divId: 'hourly-chart',
    traces: traces,
    layout: layout,
  );
}


/// Make a monthly seasonal chart.  Data from Jan24+
/// Not a lot is visible. 
///  
Plotly makeMonthlySeasonalChart(
  web.HTMLDivElement container,
  TimeSeries<num> ts,
) {
  final mTs = ts.toMonthly(mean);
  var grp = groupBy(mTs, (e) => e.interval.start.year);

  final traces = <Map<String, dynamic>>[];
  for (var year in grp.keys) {
    var yearData = grp[year]!;
    traces.add({
      'x': yearData.map((e) => e.interval.start.month).toList(),
      'y': yearData.map((e) => e.value).toList(),
      'type': 'scatter',
      'mode': 'lines+markers',
      'name': '$year',
    });
  }

  final layout = <String, dynamic>{
    'title': {'text': 'Monthly Hydro Generation from Hydro Quebec'},
    'yaxis': {
      'title': {'text': 'Hourly average, MW'},
    },
    'height': 600,
    'width': 800,
  };

  return Plotly(
    container: container,
    divId: 'monthly-seasonal-chart',
    traces: traces,
    layout: layout,
  );
}
