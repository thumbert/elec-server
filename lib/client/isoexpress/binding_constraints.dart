// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: unnecessary_cast

library elec_server.binding_constraints.v1;

import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/common_enums.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/src/utils/api_response.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client binding_constraints/v1';

class BindingConstraintsApi {
  final commons.ApiRequester _requester;
  final location = getLocation('US/Eastern');

  BindingConstraintsApi(http.Client client,
      {String rootUrl: "http://localhost:8080/", String servicePath: "bc/v1/"})
      : _requester =
            new commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);

  /// Get all the constraints in a given interval.
  ///
  /// Request parameters:
  ///
  /// [component] - Path parameter: 'component'.
  ///
  /// [ptid] - Path parameter: 'ptid'.
  ///
  /// [interval] - Path parameter: 'interval'.
  ///
  /// [bucket] - Path parameter: 'bucket'.
  ///
  /// Completes with a daily [TimeSeries].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<List<Map>> getDaBindingConstraints(Interval interval) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (interval == null) {
      throw new ArgumentError("Parameter interval is required.");
    }

    Date start = Date.fromTZDateTime(interval.start);
    Date end;
    if (isBeginningOfDay(interval.end)) {
      end =
          Date.fromTZDateTime(interval.end.subtract(new Duration(seconds: 1)));
    } else {
      end = Date.fromTZDateTime(interval.end);
    }

    _url = 'market/da' +
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
    return _response
        .then((data) => (json.decode(data['result']) as List).cast<Map>());
  }


  /// Get all the occurrences of this constraint in the history.
  Future<List<Map>> getDaBindingConstraint(String name) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (name == null) {
      throw new ArgumentError("Parameter interval is required.");
    }

    _url = 'market/da' +
        '/constraintname/' +
        commons.Escaper.ecapeVariable('${name.toString()}');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response
        .then((data) => (json.decode(data['result']) as List).cast<Map>());
  }


}
