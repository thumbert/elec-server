library elec_server.system_demand.v1;

import 'dart:async';
import 'dart:convert';
import 'package:elec/risk_system.dart';
import 'package:intl/intl.dart';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:timeseries/timeseries.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client system-demand/v1';

class SystemDemand {
  final commons.ApiRequester _requester;
  final location = getLocation('US/Eastern');

  SystemDemand(http.Client client,
      {String rootUrl: "http://localhost:8080/",
        String servicePath: "system_demand/v1/"})
      : _requester =
  new commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);

  /// Get system demand between a start and end date.
  Future<TimeSeries<double>> getSystemDemand(Market market, Date start, Date end) async {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'market/${market.toString()}' +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}');

    String columnName;
    if (market.toString().toUpperCase() == 'DA')
      columnName = 'Day-Ahead Cleared Demand';
    else if (market.toString().toUpperCase() == 'RT')
      columnName = 'Total Load';

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    var data = _response.then((data) {
      var aux = json.decode(data['result']) as List;
      var ts = TimeSeries.fromIterable(aux.map((e) => IntervalTuple<double>(
          Hour.beginning(TZDateTime.parse(location, e['hourBeginning'])), e[columnName])));
      return ts;
    });
    return data;
  }

}



