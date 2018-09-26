// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: unnecessary_cast

library elec_server.ptids.v1;

import 'dart:collection' as collection;
import 'dart:async';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client ptids/v1';

class PtidsApi {
  final commons.ApiRequester _requester;

  PtidsApi(http.Client client,
      {String rootUrl: "http://localhost:8080/",
      String servicePath: "ptids/v1/"})
      : _requester =
            new commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);

  /// Request parameters:
  ///
  /// [asOfDate] - Path parameter: 'asOfDate'.
  ///
  /// Completes with a [ApiResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<ApiResponse> apiPtidTableAsOfDate(String asOfDate) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (asOfDate == null) {
      throw new ArgumentError("Parameter asOfDate is required.");
    }

    _url = 'asofdate/' + commons.Escaper.ecapeVariable('$asOfDate');

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
  /// Completes with a [ApiResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<ApiResponse> apiPtidTableCurrent() {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'current';

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
  /// Completes with a [ListOfString].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<ListOfString> getAvailableAsOfDates() {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'dates';

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) => new ListOfString.fromJson(data));
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

class ListOfString extends collection.ListBase<String> {
  final List<String> _inner;

  ListOfString() : _inner = [];

  ListOfString.fromJson(List json)
      : _inner = json.map((value) => value).toList();

  List<String> toJson() {
    return _inner.map((value) => value).toList();
  }

  String operator [](int key) => _inner[key];

  void operator []=(int key, String value) {
    _inner[key] = value;
  }

  int get length => _inner.length;

  void set length(int newLength) {
    _inner.length = newLength;
  }
}
