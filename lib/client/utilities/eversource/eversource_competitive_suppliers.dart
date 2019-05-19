library elec_server.utilities.eversource_competitive_suppliers.v1;

import 'dart:async';
import 'dart:convert';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client eversource_competitive_suppliers/v1';

class EversourceCompetitiveSuppliers {
  final commons.ApiRequester _requester;
  final location = getLocation('US/Eastern');

  EversourceCompetitiveSuppliers(http.Client client,
      {String rootUrl: "http://localhost:8080/",
        String servicePath: "eversource_competitive_suppliers/v1/"})
      : _requester =
  commons.ApiRequester(client, rootUrl, servicePath, USER_AGENT);

  /// Get customer counts from all suppliers between two dates.
  /// For example,
  /// {"month" : "2018-12",
  //	"supplierName" : "AEQUITAS ENERGY, INC",
  //	"customerCountResidential" : 808,
  //	"customerCountBusiness" : 955}
  Future<List<Map<String, dynamic>>> getCustomerCounts(Date start, Date end,
      {String region: 'CT'}) async {
    var _url = null;
    var _queryParams = Map<String, List<String>>();
    var _uploadMedia = null;
    var _uploadOptions = null;
    var _downloadOptions = commons.DownloadOptions.Metadata;
    var _body = null;

    _url = 'customer_counts/ct' +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString().substring(0,7)}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString().substring(0,7)}');

    var _response = _requester.request(_url, "GET",
        body: _body,
        queryParams: _queryParams,
        uploadOptions: _uploadOptions,
        uploadMedia: _uploadMedia,
        downloadOptions: _downloadOptions);

    var data = await _response.then((data) {
      var xs = (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
      return xs;
    });
    return data;
  }
}
