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

class DaEnergyOffers {
  final commons.ApiRequester _requester;
  final location = getLocation('US/Eastern');

  DaEnergyOffers(http.Client client,
      {String rootUrl: "http://localhost:8080/",
      String servicePath: "da_energy_offers/v1/"})
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

  /// Get the energy offers of an asset between a start/end date
  Future<List<Map<String, dynamic>>> getDaEnergyOffersForAsset(
      int maskedAssetId, Date start, Date end) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'assetId/${maskedAssetId.toString()}' +
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
      var out =
          (json.decode(data['result']) as List).cast<Map<String, dynamic>>();
      out.forEach((e) {e['hours'] = json.decode(e['hours']);});
      return out;
    });
  }

  /// Get the generation stack for this hour
  Future<List<Map<String, dynamic>>> getGenerationStack(Hour hour) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    var aux = toIsoHourEndingStamp(hour.start);
    String startDate = aux[0];
    String hourEnding = aux[1];
    _url = 'stack/date/' +
        commons.Escaper.ecapeVariable('${startDate}') +
        '/hourending/' +
        commons.Escaper.ecapeVariable('${hourEnding}');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) =>
        (json.decode(data['result']) as List).cast<Map<String, dynamic>>());
  }

  /// Get the masked asset id and the masked participant id for this date.
  Future<List<Map<String, dynamic>>> assetsForDay(Date date) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'assets/day/' + commons.Escaper.ecapeVariable('${date.toString()}');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) =>
        (json.decode(data['result']) as List).cast<Map<String, dynamic>>());
  }

  /// Get the masked asset ids of a masked participant id between a start and end date.
  Future<List<Map<String, dynamic>>> assetsForParticipantId(int maskedParticipantId,
      Date start, Date end) {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'assets/participantId/${maskedParticipantId}' +
        '/start/' + commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' + commons.Escaper.ecapeVariable('${end.toString()}');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response.then((data) =>
        (json.decode(data['result']) as List).cast<Map<String, dynamic>>());
  }


  /// Get the last date inserted in the database
  Future<Date> lastDate() {
    var _url = null;
    var _queryParams = new Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'lastday';

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);
    return _response
        .then((data) => Date.parse(json.decode(data['result']) as String));
  }
}
