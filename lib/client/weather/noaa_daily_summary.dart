library client.weather.noaa_daily_summary;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:http/http.dart' as http;

class NoaaDailySummary {
  NoaaDailySummary(this.client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/noaa_daily_summary/v1/'});

  final http.Client client;
  final String rootUrl;
  final String servicePath;

  /// from airport code to stationId
  static const airportCodeMap = <String, String>{
    'ATL': 'USW00013874', // Atlanta
    'BOS': 'USW00014739', // Boston
    'BWI': 'USW00093721', // Baltimore
    'LGA': 'USW00014732', // NYC La Guardia
    'ORD': 'USW00094846', // Chicago O'Hare
  };

  /// Daily average temperature in Fahrenheit.
  Future<TimeSeries<num>> getDailyHistoricalTemperature(
      String airportCode, Interval interval) async {
    var data = await getDailyHistoricalMinMaxTemperature(airportCode, interval);
    var out = TimeSeries.fromIterable(data.map((e) {
      var value = 0.5 * (e.value['min']! + e.value['max']!);
      return IntervalTuple(e.interval, value);
    }));

    return out;
  }

  /// Return temperature data for a given 3 letter [airportCode].
  /// For example, Boston is 'BOS'.  Temperature is in Fahrenheit.
  /// ```
  ///   '2019-01-15' -> {'min': 24, 'max': 39},
  ///   '2019-01-16' -> {'min': 22, 'max': 40},
  ///   ...
  /// ```
  Future<TimeSeries<Map<String, num>>> getDailyHistoricalMinMaxTemperature(
      String airportCode, Interval interval) async {
    var stationId = airportCodeMap[airportCode]!;
    var location = interval.start.location;
    var start = interval.start.toString().substring(0, 10);
    var end =
        interval.end.subtract(Duration(minutes: 1)).toString().substring(0, 10);
    var _url =
        rootUrl + servicePath + 'stationId/$stationId/start/$start/end/$end';

    var _response = await client.get(Uri.parse(_url));
    var xs = json.decode(_response.body) as List;

    return TimeSeries.fromIterable(xs.map((e) => IntervalTuple(
        Date.parse(e['date'], location: location),
        {'min': e['tMin'], 'max': e['tMax']})));
  }
}
