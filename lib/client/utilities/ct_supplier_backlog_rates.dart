library elec_server.utilities.eversource_competitive_suppliers.v1;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/utilities/ct_supplier_backlog_rates.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

class CtSupplierBacklogRates {
  CtSupplierBacklogRates(http.Client client, {required this.rootUrl});

  final String rootUrl;
  final String servicePath = '/retail_suppliers/v1/ct/supplier_backlog_rates';

  /// Get backlog data from all suppliers between two months.
  Future<List<Map<String, dynamic>>> getBacklogForUtility(
      {required Utility utility,
      required Month start,
      required Month end}) async {
    var url = '$rootUrl$servicePath/utility/${utility.toString()}'
        '/start/${start.toIso8601String()}'
        '/end/${end.toIso8601String()}';

    var response = await http.get(Uri.parse(url));
    var data =
        (json.decode(response.body) as List).cast<Map<String, dynamic>>();
    return data;
  }
}
