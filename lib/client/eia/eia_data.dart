library api.eia;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

const String USER_AGENT = 'dart-api-client eia/v1';

class EiaApi {
  /// this is the api key that you request from eia
  final String? apiKey;
  String rootUrl;

  EiaApi(http.Client client, this.apiKey,
      {this.rootUrl = 'http://api.eia.gov/series/'});

  /// Request parameters:
  ///
  /// [id] - Series id, e.g. 'NG.NW2_EPG0_SWO_R48_BCF.W' for the weekly working
  /// gas in underground storage.
  ///
  /// Completes with a daily [TimeSeries].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<Map<String, dynamic>> getSeries(String id) async {
    if (id == null) {
      throw ArgumentError('Parameter id is required.');
    }

    var _url = rootUrl + '?api_key=$apiKey&series_id=$id';
    var aux = await http.get(Uri.parse(_url));
    var data = json.decode(aux.body) as Map;
    return (data['series'] as List).first;
  }
}

/// Create a timeseries from the EIA series data.
/// Note that input [data] has most recent data first, so data needs
/// to be reversed.
TimeSeries<num?> processSeries(Map<String, dynamic> data) {
  var ts = TimeSeries<num?>();
  var xs = data['data'] as List;
  var n = xs.length;
  for (var i = n - 1; i >= 0; i--) {
    ts.add(IntervalTuple(Date.parse(xs[i][0]), xs[i][1]));
  }
  return ts;
}
