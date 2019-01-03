library api.eia;

import 'dart:async';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client eia/v1';

class EiaApi {
  final commons.ApiRequester _requester;

  /// this is the api key that you request from eia
  final String apiKey;

  EiaApi(http.Client client, this.apiKey,
      {String rootUrl: "http://api.eia.gov/series/"})
      : _requester = new commons.ApiRequester(client, rootUrl, '', USER_AGENT);


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
  Future<Map<String,dynamic>> getSeries(String id) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (id == null) {
      throw new ArgumentError("Parameter id is required.");
    }

    _url = '?api_key=$apiKey&series_id=$id';
    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) {
      return (data['series'] as List).first;
    });
  }
}


/// Create a timeseries from the EIA series data.
TimeSeries<num> processSeries(Map<String,dynamic> data) {
  var ts = TimeSeries<num>();
  var xs = data['data'] as List;
  var n = xs.length;
  Date start, end;
  if (data['f'] == 'W') {
    // frequency of data is weekly
    for (int i=n-1; i>=0; i--) {
      if (i == n-1) {
        start = Date.parse(xs[n-1][0]).subtract(7);
      } else {
        start = end;
      }
      end = Date.parse(xs[i][0]);
      ts.add(IntervalTuple(Interval(start.end, end.end), xs[i][1]));
    }
  }
  return ts;
}
