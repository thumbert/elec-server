// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: unnecessary_cast

library elec_server.ptids.v1;

import 'dart:convert';
import 'dart:async';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';


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
  /// [asOfDate] - Path parameter: 'asOfDate'.  If [null] return the last
  /// date in the database.
  ///
  /// Completes with a [ApiResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  Future<List<Map<String,Object>>> getPtidTable({Date asOfDate}) async {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (asOfDate == null) {
      _url = 'current';
    } else {
      _url = 'asofdate/' + commons.Escaper.ecapeVariable('$asOfDate');
    }

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) {
      var aux = new ApiResponse.fromJson(data);
      return (json.decode(aux.result) as List).cast<Map<String,Object>>();
    });

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


