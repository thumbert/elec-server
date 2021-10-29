library client.weather.noaa_daily_summary;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';

class NoaaDailySummary {
  NoaaDailySummary(this.client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/noaa_daily_summary/v1/'});

  final http.Client client;
  final String rootUrl;
  final String servicePath;

  /// from airport code to stationId
  static const airportCodeMap = <String, String>{
    'BOS': 'USW00014739',
  };

  /// Daily average temperature in Fahrenheit.
  Future<TimeSeries<num>> getHistoricalTemperature(
      String airportCode, Date start, Date end) async {
    var data = await getHistoricalMinMaxTemperature(airportCode, start, end);
    var out = TimeSeries.fromIterable(data.map((e) {
      var value = (e['tMin'] + e['tMax']) / 2 as num; // in Celsius
      return IntervalTuple(Date.parse(e['date'], location: UTC), value);
    }));

    return out;
  }

  /// Return temperature data for a given 3 letter [airportCode].
  /// For example, Boston is 'BOS'.  Temperature is in Fahrenheit.
  /// ```
  /// {
  ///   'date': '2019-01-15',
  ///   'tMin': 24,
  ///   'tMax': 39,
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getHistoricalMinMaxTemperature(
      String airportCode, Date start, Date end) async {
    var stationId = airportCodeMap[airportCode]!;
    var _url =
        rootUrl + servicePath + 'stationId/$stationId/start/$start/end/$end';

    var _response = await client.get(Uri.parse(_url));
    var xs = (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
    return xs;
  }
}
