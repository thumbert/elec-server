library elec_server.utilities.eversource_load.v1;

import 'dart:async';
import 'dart:convert';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:timeseries/timeseries.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client utilities/eversource/load/v1';

class EversourceLoad {
  final commons.ApiRequester _requester;
  final location = getLocation('US/Eastern');

  EversourceLoad(http.Client client,
      {String rootUrl: "http://localhost:8080/",
      String servicePath: "eversource_load/v1/"})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);

  /// Get hourly prices for a ptid between a start and end date.
  Future<TimeSeries<Map<String, num>>> getCtLoad(Date start, Date end) async {
    var _url = null;
    var _queryParams = Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'zone/ct' +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    var data = _response.then((data) {
      var aux = json.decode(data['result']) as List;
      var ts = TimeSeries.fromIterable(aux.map((e) =>
          IntervalTuple<Map<String, num>>(
              Hour.beginning(TZDateTime.parse(location, e['hourBeginning'])),
              e)));
      return ts;
    });
    return data;
  }
}
