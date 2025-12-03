import 'dart:io';

import 'package:dama/stat/descriptive/quantile.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/utils.dart';
import 'package:timezone/data/latest_10y.dart';

void dailyWaterLevelAllIds(Report report) {
  final archive = getHqWaterArchive();
  final data = archive.dailyWaterLevel();

  final traces = <Map<String,dynamic>>[];
  for (final stationId in data.keys) {
    final ts = data[stationId]!;
    final median = Quantile(ts.map((e) => e.value).toList()).median();
    traces.add({
      'x': ts
          .map((e) => e.interval.start.toIso8601String().substring(0, 10))
          .toList(),
      'y': ts.map((e) => e.value - median).toList(),
      'type': 'scatter',
      'mode': 'lines+markers',
      'name': stationId,
    });
  }  
  final layout = {
    'height': 900,
    'title': 'Daily Water Level',
    'xaxis': {'title': 'Date'},
    'yaxis': {'title': 'Water Level (m)'},
  };
  final file = File('${report.dir}/daily_water_level_by_station_id.html');
  Plotly.now(traces, layout, file: file);
}


void totalDailyWaterLevel(Report report) {
  final archive = getHqWaterArchive();
  final ts = archive.totalDailyWaterLevel();

  print(ts);

  final traces = [
    {
      'x': ts
          .map((e) => e.interval.start.toIso8601String().substring(0, 10))
          .toList(),
      'y': ts.map((e) => e.value).toList(),
      'type': 'scatter',
      'mode': 'lines+markers',
      'name': 'Total Daily Water Level',
    },
  ];
  final layout = {
    'width': 800,
    'height': 600,
    'title': 'Total Daily Water Level',
    'xaxis': {'title': 'Date'},
    'yaxis': {'title': 'Water Level (m)'},
  };
  final file = File('${report.dir}/total_daily_water_level.html');

  Plotly.now(traces, layout, file: file);
}

class Report {
  Report({required this.dir});
  final String dir;
}

void main(List<String> args) {
  initializeTimeZones();

  final report = Report(
      dir:
          '${Platform.environment['HOME'] ?? ''}/Documents/reports/HQ_water_level');

  totalDailyWaterLevel(report);
  dailyWaterLevelAllIds(report);
  print('Done. See ${report.dir} for the reports.');
}
