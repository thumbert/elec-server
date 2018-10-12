// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: unnecessary_cast

library elec_server.dalmp.v1;

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
      var x = (json.decode(data['result']) as List).cast<Map>();
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
  Future<TimeSeries> getHourlyData(
      LmpComponent component, int ptid, Interval interval) {
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

    String cmp = component.toString().replaceAll('LmpComponent.', '');
    Date start = Date.fromTZDateTime(interval.start);
    Date end;
    if (isBeginningOfDay(interval.end)) {
      end =
          Date.fromTZDateTime(interval.end.subtract(new Duration(seconds: 1)));
    } else {
      end = Date.fromTZDateTime(interval.end);
    }


    _url = 'component/' +
        commons.Escaper.ecapeVariable('$cmp') +
        '/ptid/' +
        commons.Escaper.ecapeVariable('$ptid') +
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
    return _response.then((data) {
      var x = (json.decode(data['result']) as List).cast<Map>();
      return TimeSeries.fromIterable(x.map((e) => new IntervalTuple(
          new Hour.beginning(TZDateTime.parse(location, e['hourBeginning'])), e[cmp])));
    });
  }

  /// Request parameters:
  ///
  /// [component] - Path parameter: 'component'.
  ///
  /// [ptid] - Path parameter: 'ptid'.
  ///
  /// [interval] - Path parameter: 'interval'.
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
  Future<TimeSeries> getMonthlyBucketPrice(
      LmpComponent component, int ptid, Interval interval, Bucket bucket) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;
    final DateFormat _isoFmt = new DateFormat('yyyy-MM');

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
    Month start = Month.fromTZDateTime(interval.start);
    Month end;
    if (isBeginningOfMonth(interval.end)) {
      end =
          Month.fromTZDateTime(interval.end.subtract(new Duration(seconds: 1)));
    } else {
      end = Month.fromTZDateTime(interval.end);
    }

    _url = 'monthly/' +
        commons.Escaper.ecapeVariable('$cmp') +
        '/ptid/' +
        commons.Escaper.ecapeVariable('$ptid') +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toIso8601String()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toIso8601String()}') +
        '/bucket/' +
        commons.Escaper.ecapeVariable('${bucket.name}');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) {
      var x = (json.decode(data['result']) as List).cast<Map>();
      return TimeSeries.fromIterable(x.map((e) => new IntervalTuple(
          Month.parse(e['month'], fmt: _isoFmt, location: location), e[cmp])));
    });
  }
}


