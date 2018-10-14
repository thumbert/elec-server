// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: unnecessary_cast

library elec_server.da_energy_offer.v1;

import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:elec_server/src/utils/api_response.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client da_energy_offer/v1';

class DaEnergyOfferApi {
  final commons.ApiRequester _requester;
  final location = getLocation('US/Eastern');

  DaEnergyOfferApi(http.Client client,
      {String rootUrl: "http://localhost:8080/", String servicePath: "da_energy_offers/v1/"})
      : _requester =
  new commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);

  /// Get all the energy offers for a given hour.  All assets.
  Future<List<Map>> getDaEnergyOffers(Hour hour) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    if (hour == null) {
      throw new ArgumentError("Parameter hour is required.");
    }

    var aux = toIsoHourEndingStamp(hour.start);
    String startDate = aux[0];
    String hourEnding = aux[1];
    _url = 'date/' +
        commons.Escaper.ecapeVariable('${startDate}') +
        '/hourending/' +
        commons.Escaper.ecapeVariable('${hourEnding}');

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
//  Future<List<Map>> getDaBindingConstraint(String name) {
//    var _url = null;
//    var _queryParams = new Map<String, List<String>>();
//    var _uploadMedia = null;
//    var _uploadOptions = null;
//    var _downloadOptions = commons.DownloadOptions.Metadata;
//    var _body = null;
//
//    if (name == null) {
//      throw new ArgumentError("Parameter interval is required.");
//    }
//
//    _url = 'market/da' +
//        '/constraintname/' +
//        commons.Escaper.ecapeVariable('${name.toString()}');
//
//    var _response = _requester.request(_url, "GET",
//        body: _body,
//        queryParams: _queryParams,
//        uploadOptions: _uploadOptions,
//        uploadMedia: _uploadMedia,
//        downloadOptions: _downloadOptions);
//    return _response
//        .then((data) => (json.decode(data['result']) as List).cast<Map>());
//  }


}
