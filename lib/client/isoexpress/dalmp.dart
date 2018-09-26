// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: unnecessary_cast

library elec_server.dalmp.v1;

import 'dart:collection' as collection;
import 'dart:async';
import 'dart:convert';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/common_enums.dart';
import 'package:timeseries/timeseries.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client dalmp/v1';

class DalmpApi {
  final commons.ApiRequester _requester;
  final location = getLocation('US/Eastern');

  DalmpApi(http.Client client,
      {String rootUrl: "http://localhost:8080/",
      String servicePath: "dalmp/v1/"})
      : _requester =
            new commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);

  /// Request parameters:
  ///
  /// Completes with a [ListOfint].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<ListOfint> allPtids() {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'ptids';

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => new ListOfint.fromJson(data));
  }

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
  Future<TimeSeries> getDailyBucketPrice(
      LmpComponent component, int ptid, Interval interval, Bucket bucket) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (component == null) {
      throw new ArgumentError("Parameter component is required.");
    }
    if (ptid == null) {
      throw new ArgumentError("Parameter ptid is required.");
    }
    if (interval == null) {
      throw new ArgumentError("Parameter interval is required.");
    }
    if (bucket == null) {
      throw new ArgumentError("Parameter bucket is required.");
    }

    String cmp = component.toString().replaceAll('LmpComponent.', '');
    Date start = Date.fromTZDateTime(interval.start);
    Date end;
    if (isBeginningOfDay(interval.end)) {
      end =
          Date.fromTZDateTime(interval.end.subtract(new Duration(seconds: 1)));
    } else {
      end = Date.fromTZDateTime(interval.end);
    }

    _url = 'daily/' +
        commons.Escaper.ecapeVariable('$cmp') +
        '/ptid/' +
        commons.Escaper.ecapeVariable('$ptid') +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}') +
        '/bucket/' +
        commons.Escaper.ecapeVariable('${bucket.name}');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) {
      var aux = new ApiResponse.fromJson(data);
      var x = (json.decode(aux.result) as List).cast<Map>();
      return TimeSeries.fromIterable(x.map((e) => new IntervalTuple(
          Date.parse(e['date'], location: location), e[cmp])));
    });
  }

  /// Request parameters:
  ///
  /// [component] - Path parameter: 'component'.
  ///
  /// [ptid] - Path parameter: 'ptid'.
  ///
  /// [start] - Path parameter: 'start'.
  ///
  /// [end] - Path parameter: 'end'.
  ///
  /// Completes with a [ApiResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<ApiResponse> getHourlyData(
      String component, int ptid, String start, String end) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (component == null) {
      throw new ArgumentError("Parameter component is required.");
    }
    if (ptid == null) {
      throw new ArgumentError("Parameter ptid is required.");
    }
    if (start == null) {
      throw new ArgumentError("Parameter start is required.");
    }
    if (end == null) {
      throw new ArgumentError("Parameter end is required.");
    }

    _url = 'component/' +
        commons.Escaper.ecapeVariable('$component') +
        '/ptid/' +
        commons.Escaper.ecapeVariable('$ptid') +
        '/start/' +
        commons.Escaper.ecapeVariable('$start') +
        '/end/' +
        commons.Escaper.ecapeVariable('$end');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => new ApiResponse.fromJson(data));
  }

  /// Request parameters:
  ///
  /// [component] - Path parameter: 'component'.
  ///
  /// [ptid] - Path parameter: 'ptid'.
  ///
  /// [start] - Path parameter: 'start'.
  ///
  /// [end] - Path parameter: 'end'.
  ///
  /// [bucket] - Path parameter: 'bucket'.
  ///
  /// Completes with a [ApiResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<ApiResponse> getMonthlyBucketPrice(
      String component, int ptid, String start, String end, String bucket) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (component == null) {
      throw new ArgumentError("Parameter component is required.");
    }
    if (ptid == null) {
      throw new ArgumentError("Parameter ptid is required.");
    }
    if (start == null) {
      throw new ArgumentError("Parameter start is required.");
    }
    if (end == null) {
      throw new ArgumentError("Parameter end is required.");
    }
    if (bucket == null) {
      throw new ArgumentError("Parameter bucket is required.");
    }

    _url = 'monthly/' +
        commons.Escaper.ecapeVariable('$component') +
        '/ptid/' +
        commons.Escaper.ecapeVariable('$ptid') +
        '/start/' +
        commons.Escaper.ecapeVariable('$start') +
        '/end/' +
        commons.Escaper.ecapeVariable('$end') +
        '/bucket/' +
        commons.Escaper.ecapeVariable('$bucket');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => new ApiResponse.fromJson(data));
  }
}

class ApiResponse {
  String result;

  ApiResponse();

  ApiResponse.fromJson(Map _json) {
    if (_json.containsKey("result")) {
      result = _json["result"];
    }
  }

  Map<String, Object> toJson() {
    final Map<String, Object> _json = new Map<String, Object>();
    if (result != null) {
      _json["result"] = result;
    }
    return _json;
  }
}

class ListOfint extends collection.ListBase<int> {
  final List<int> _inner;

  ListOfint() : _inner = [];

  ListOfint.fromJson(List json) : _inner = json.map((value) => value).toList();

  List<int> toJson() {
    return _inner.map((value) => value).toList();
  }

  int operator [](int key) => _inner[key];

  void operator []=(int key, int value) {
    _inner[key] = value;
  }

  int get length => _inner.length;

  void set length(int newLength) {
    _inner.length = newLength;
  }
}
