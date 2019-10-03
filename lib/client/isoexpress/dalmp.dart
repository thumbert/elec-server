library elec_server.dalmp.v1;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/common_enums.dart';
import 'package:timeseries/timeseries.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client dalmp/v1';

class DaLmp {
  String rootUrl;
  String servicePath;
  final location = getLocation('US/Eastern');
  static final DateFormat _mthFmt = new DateFormat('yyyy-MM');

  DaLmp(http.Client client,
      {this.rootUrl: "http://localhost:8080/",
      this.servicePath: "dalmp/v1/"});

  /// Get hourly prices for a ptid between a start and end date.
  Future<TimeSeries<double>> getHourlyLmp(int ptid, LmpComponent component,
      Date start, Date end) async {
    var cmp = component.toString().substring(13);
    var _url = rootUrl + servicePath +
        'hourly/$cmp/ptid/' +
        commons.Escaper.ecapeVariable('${ptid.toString()}') +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
      var aux = json.decode(data['result']) as List;
      var ts = TimeSeries.fromIterable(aux.map((e) => IntervalTuple<double>(
          Hour.beginning(TZDateTime.parse(location, e['hourBeginning'])), e[cmp])));
      return ts;


  }


  /// Get daily prices for a ptid/bucket between a start and end date.
//  Future<TimeSeries<double>> getDailyLmpBucket(int ptid, LmpComponent component,
//      Bucket bucket, Date start, Date end) async {
//    var _url = null;
//    var _queryParams = new Map<String, List<String>>();
//    var _uploadMedia = null;
//    var _uploadOptions = null;
//    var _downloadOptions = commons.DownloadOptions.Metadata;
//    var _body = null;
//
//    String cmp = component.toString().substring(13);
//
//    _url = 'daily/$cmp/ptid/' +
//        commons.Escaper.ecapeVariable('${ptid.toString()}') +
//        '/start/' +
//        commons.Escaper.ecapeVariable('${start.toString()}') +
//        '/end/' +
//        commons.Escaper.ecapeVariable('${end.toString()}') +
//        '/bucket/' +
//        commons.Escaper.ecapeVariable('${bucket.name.toString()}');
//
//    var _response = _requester.request(_url, "GET",
//        body: _body,
//        queryParams: _queryParams,
//        uploadOptions: _uploadOptions,
//        uploadMedia: _uploadMedia,
//        downloadOptions: _downloadOptions);
//    var data = _response.then((data) {
//      var aux = json.decode(data['result']) as List;
//      var ts = TimeSeries.fromIterable(aux.map((e) => IntervalTuple<double>(
//          Date.parse(e['date'], location: location), e[cmp])));
//      return ts;
//    });
//    return data;
//  }

  /// get the daily prices for all nodes in the db as calculated by mongo
//  Future<Map<int,TimeSeries<num>>> getDailyPricesAllNodes(LmpComponent component,
//      Date start, Date end) async {
//    var _url = null;
//    var _queryParams = new Map<String, List<String>>();
//    var _uploadMedia = null;
//    var _uploadOptions = null;
//    var _downloadOptions = commons.DownloadOptions.Metadata;
//    var _body = null;
//
//    String cmp = component.toString().substring(13);
//
//    _url = 'daily/mean/$cmp' +
//        '/start/' +
//        commons.Escaper.ecapeVariable('${start.toString()}') +
//        '/end/' +
//        commons.Escaper.ecapeVariable('${end.toString()}');
//
//    var _response = _requester.request(_url, "GET",
//        body: _body,
//        queryParams: _queryParams,
//        uploadOptions: _uploadOptions,
//        uploadMedia: _uploadMedia,
//        downloadOptions: _downloadOptions);
//
//    var out = <int,TimeSeries<num>>{};
//
//    await _response.then((data) {
//      var aux = json.decode(data['result']) as List;
//      // group by ptid
//      var grp = groupBy(aux, (e) => e['ptid'] as int);
//      for (var ptid in grp.keys) {
//        out[ptid] = TimeSeries.fromIterable(grp[ptid].map((e) => IntervalTuple<double>(
//            Date.parse(e['date'], location: location), e[cmp])));
//      }
//    });
//
//    return out;
//  }


  /// Get monthly prices for a ptid/bucket between a start and end date.
//  Future<TimeSeries<double>> getMonthlyLmpBucket(int ptid, LmpComponent component,
//      Bucket bucket, Month start, Month end) async {
//    var _url = null;
//    var _queryParams = new Map<String, List<String>>();
//    var _uploadMedia = null;
//    var _uploadOptions = null;
//    var _downloadOptions = commons.DownloadOptions.Metadata;
//    var _body = null;
//
//    String cmp = component.toString().substring(13);
//
//    _url = 'monthly/$cmp/ptid/' +
//        commons.Escaper.ecapeVariable('${ptid.toString()}') +
//        '/start/' +
//        commons.Escaper.ecapeVariable('${start.toIso8601String()}') +
//        '/end/' +
//        commons.Escaper.ecapeVariable('${end.toIso8601String()}') +
//        '/bucket/' +
//        commons.Escaper.ecapeVariable('${bucket.name.toString()}');
//
//    var _response = _requester.request(_url, "GET",
//        body: _body,
//        queryParams: _queryParams,
//        uploadOptions: _uploadOptions,
//        uploadMedia: _uploadMedia,
//        downloadOptions: _downloadOptions);
//    var data = _response.then((data) {
//      var aux = json.decode(data['result']) as List;
//      var ts = TimeSeries.fromIterable(aux.map((e) => IntervalTuple<double>(
//          Month.parse(e['month'], location: location, fmt: _mthFmt), e[cmp])));
//      return ts;
//    });
//    return data;
//  }


}



