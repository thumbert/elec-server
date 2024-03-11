library src.weather.weather_norm;

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dama/analysis/interpolation/multi_linear_interpolator.dart';
import 'package:dama/basic/linear_filter.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/utils.dart';
import 'package:timeseries/timeseries.dart';

class NormalTemperatureArchive {
  NormalTemperatureArchive({ComponentConfig? dbConfig, String? dir}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1',
            dbName: 'weather',
            collectionName: 'normal_temperature');
    this.dir = dir ??
        '${Platform.environment['HOME']}/Downloads/Archive/Weather/NormalTemperature';
  }

  late final ComponentConfig dbConfig;
  late final String dir;

  /// Insert/Update a list of documents into the db.
  /// ```
  ///   {
  ///     'airportCode': 'BOS',
  ///     'asOfDate': '2024-03-01',
  ///     'normalTemperature': <double>[...],
  ///   }
  /// ```
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
      for (var x in data) {
        await dbConfig.coll.remove({
          'airportCode': x['airportCode'],
        });
        await dbConfig.coll.insert(x);
        print(
            '--->  Inserted normal temperature for airport ${x['airportCode']} successfully');
      }
    } catch (e) {
      print('XXX $e');
      return Future.value(1);
    }
    return Future.value(0);
  }

  /// json file input
  Map<String, dynamic> processFile(File file) {
    var contents = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    return switch (contents) {
      {
        'airportCode': String _,
        'asOfDate': String _,
        'normalTemperature': List<dynamic> _,
      } =>
        contents,
      _ => throw StateError('Invalid file format!'),
    };
  }
}

class NormalTemperatureAnalysis {
  NormalTemperatureAnalysis(this.ts, {required this.dir});

  /// A daily timeseries of values in F for a given location
  TimeSeries<({num min, num max})> ts;

  /// Where reports will be generated
  Directory dir;

  /// Calculate what is considered normal temperature
  /// for the immediate future (next year).
  ///
  /// Return 366 values, for each day of the year
  List<num>? _normalTemperature;

  List<num> normalTemperature() {
    if (_normalTemperature == null) {
      throw StateError('Need to run makeReport() first!');
    }
    return _normalTemperature!;
  }

  /// Make sure that the temperature adjustor function is consistent
  /// with the baseline values.
  /// Assume linear departure from the baseline
  final allAdjustors = <String, MultiLinearInterpolator>{
    'BOS': MultiLinearInterpolator([
      0.0, // a point very back in the past
      Date.utc(2010, 1, 1).value, // when baseline starts shifting
      Date.utc(2024, 1, 1).value, // when no more adjustment is needed
      double.maxFinite
    ], [
      2.5, // adjust values by this much (up)
      2.5, // adjust values by linear interpolation between this and zero
      0.0, // no more adjustment is needed
      0.0
    ]),
  };
  final allBaseline = <String, ({num baselineT, num currentT})>{
    'BOS': (baselineT: 51.75, currentT: 54.25),
  };

  void makeReport(String airport) {
    // calculate annual temperatures to look for global warming
    // should remove 29-Feb from leap years too because they add an extra cold day
    final yTemp =
        toYearly(ts, (xs) => xs.map((e) => 0.5 * (e.max + e.min)).mean());
    if (ts.last.interval.start.month != 12 &&
        ts.last.interval.start.day != 31) {
      // remove incomplete years
      yTemp.removeLast();
    }

    var years = yTemp.map((e) => e.interval.start.year.toDouble()).toList();
    var ma = movingAverageFilter(yTemp.values.toList(), List.filled(10, 0.1));

    /// To capture global warming:
    /// - I tried to do a quadratic regression T ~ 1 + year + year^2.
    ///   Didn't work very well.
    /// - Settled on a piecewise-linear function, see below.
    ///
    /// Adjust historical temperature because of global warming
    final adjustor = allAdjustors[airport]!;
    var adjustedTs = ts.map((e) {
      var avg = 0.5 * (e.value.max + e.value.min);
      return IntervalTuple(
          e.interval, avg + adjustor.valueAt((e.interval as Date).value));
    }).toTimeSeries();

    /// Calculate average T by day of year
    var aux = groupBy(adjustedTs, (e) => (e.interval as Date).dayOfYear());
    var doyTemp = aux.values.map((e) {
      return mean(e.map((f) => f.value));
    }).toList();
    var q25 = aux.values.map((e) {
      return Quantile(e.map((f) => f.value).toList()).value(0.25);
    }).toList();
    q25 = smoothDoyTemps(q25);
    var q75 = aux.values.map((e) {
      return Quantile(e.map((f) => f.value).toList()).value(0.75);
    }).toList();
    q75 = smoothDoyTemps(q75);
    // smooth the average T by day of year because it still has too much noise
    var smoothedDoyTemp = smoothDoyTemps(doyTemp);
    smoothedDoyTemp = smoothDoyTemps(smoothedDoyTemp);
    smoothedDoyTemp = smoothDoyTemps(smoothedDoyTemp);
    _normalTemperature = [...smoothedDoyTemp];

    /// Make full year annual temperature plot, show adjustment
    plotYearAvg() {
      final (baselineT: bT, currentT: cT) = allBaseline[airport]!;
      var adj = allAdjustors['BOS']!;

      var traces = <Map<String, dynamic>>[
        {
          'x': yTemp.map((e) => e.interval.start.year).toList(),
          'y': yTemp.map((e) => e.value).toList(),
          'mode': 'markers',
          'name': 'actual',
        },
        {
          'x': years,
          'y': ma,
          'mode': 'lines',
          'name': 'MA(10)',
        },
        {
          'x': [
            1970,
            Date.fromJulianDay(adj.xs[1].toInt()).year,
            Date.fromJulianDay(adj.xs[2].toInt()).year
          ],
          'y': [bT, bT, cT],
          'mode': 'lines',
          'name': 'empirical',
        }
      ];
      const layout = {
        'title': '',
        'xaxis': {
          'title': 'Year',
        },
        'yaxis': {
          'title': 'Average Temperature, F',
        },
        'height': 650,
        'width': 800
      };
      var file = File('${dir.path}/annual_temps_full.html');
      Plotly.now(traces, layout, file: file);
    }

    /// Plot avg T vs. day of year, show smoothed values
    plotAvgTvsDayOfYear() {
      var traces = <Map<String, dynamic>>[
        {
          'x': List.generate(doyTemp.length, (i) => i),
          'y': doyTemp,
          'name': 'Average',
          'mode': 'markers',
        },
        {
          'x': List.generate(doyTemp.length, (i) => i),
          'y': smoothedDoyTemp,
          'name': 'Smoothed',
          'mode': 'lines',
        },
        {
          'x': List.generate(doyTemp.length, (i) => i),
          'y': q25,
          'name': '1st Quantile (smoothed)',
          'mode': 'lines',
          'line': {
            'color': '#D3D3D3',
          }
        },
        {
          'x': List.generate(doyTemp.length, (i) => i),
          'y': q75,
          'name': '3rd Quantile (smoothed)',
          'mode': 'lines',
          'line': {
            'color': '#D3D3D3',
          }
        },
      ];
      final layout = {
        'title': '',
        'xaxis': {
          'title': 'Day of year',
        },
        'yaxis': {
          'title': 'Temperature, F',
        },
        'legend': {"orientation": "h"},
        'height': 650,
        'width': 800
      };
      var file = File('${dir.path}/temps_by_doy.html');
      Plotly.now(traces, layout, file: file);
    }

    /// Make partial year (year to date) temperature plot
    plotPartialYearAvg() {
      var gTs = ts.splitByIndex((interval) => interval.start.year);
      var lastYear = ts.last.interval.start.year;
      var nDays = gTs[lastYear]!.length;

      var yTemp = gTs.entries.map((e) => e.value
          .sublist(0, nDays)
          .map((e) => 0.5 * (e.value.max + e.value.min))
          .mean());

      var traces = <Map<String, dynamic>>[
        {
          'x': gTs.keys.toList(),
          'y': yTemp.toList(),
          'mode': 'markers',
        }
      ];
      final layout = {
        'title': '',
        'xaxis': {
          'title': 'Partial Year (up to day $nDays)',
        },
        'yaxis': {
          'title': 'Average Temperature, F',
        },
        'height': 650,
        'width': 800
      };
      var file = File('${dir.path}/annual_temps_partial.html');
      Plotly.now(traces, layout, file: file);
    }

    // plotYearAvg();
    // plotPartialYearAvg();
    // plotAvgTvsDayOfYear();

    var jsonFile = File('${getNormalTemperatureArchive().dir}/$airport.json');
    jsonFile.writeAsStringSync(json.encode({
      'airportCode': airport,
      'asOfDate': ts.last.interval.toString(),
      'normalTemperature': _normalTemperature!
          .map((e) => num.parse(e.toStringAsFixed(1)))
          .toList(),
    }));
    print('Wrote file ${jsonFile.path}');
  }

  /// A procedure to smooth the input 366 values.
  /// Use a moving average circular binomial filter.
  List<num> smoothDoyTemps(List<num> x) {
    assert(x.length == 366);
    return binomialFilter(x, 30, circular: true).cast<num>();
  }
}
