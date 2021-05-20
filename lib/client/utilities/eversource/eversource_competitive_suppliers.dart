library elec_server.utilities.eversource_competitive_suppliers.v1;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';


class EversourceCompetitiveSuppliers {
  final location = getLocation('America/New_York');
  String rootUrl;
  final String servicePath = 'eversource_competitive_suppliers/v1/';

  EversourceCompetitiveSuppliers(http.Client client,
      {String rootUrl = 'http://localhost:8080'});

  /// Get customer counts from all suppliers between two dates.
  /// For example,
  /// {"month" : "2018-12",
  //	"supplierName" : "AEQUITAS ENERGY, INC",
  //	"customerCountResidential" : 808,
  //	"customerCountBusiness" : 955}
  Future<List<Map<String, dynamic>>> getCustomerCounts(Date start, Date end,
      {String region = 'CT'}) async {

    var _url = rootUrl + servicePath + 'customer_counts/ct' +
        '/start/${start.toString().substring(0,7)}' +
        '/end/${end.toString().substring(0,7)}';

    var _response = await http.get(Uri.parse(_url));
    var data = (json.decode(_response.body) as List).cast<Map<String,dynamic>>();
    return data;
  }
}
