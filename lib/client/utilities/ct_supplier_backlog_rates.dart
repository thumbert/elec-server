import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';

enum Utility {
  eversource('Eversource'),
  ui('UI');

  const Utility(this._value);
  final String _value;

  static Utility parse(String x) {
    return switch (x.toLowerCase()) {
      'eversource' => eversource,
      'ui' => ui,
      _ => throw ArgumentError('Don\'t know how to parse $x'),
    };
  }

  @override
  String toString() => _value;
}

class CtSupplierBacklogRates {
  CtSupplierBacklogRates(http.Client client, {required this.rootUrl});

  final String rootUrl;
  final String servicePath = '/retail_suppliers/v1/ct/supplier_backlog_rates';

  /// Get backlog data from all suppliers between two months.  Return data
  /// sorted by month, each element in this shape:
  ///```
  ///{
  ///  'month': '2023-01',
  ///  'utility': 'Eversource',
  ///  'customerClass': 'C&I',
  ///  'supplierName': 'CATALYST POWER & GAS LLC',
  ///  'price': <num>[...],
  ///  'kWh': <num>[...],
  ///  'summary': {
  ///    'customerCount': 97,
  ///    'averagePriceWeightedByCustomerCount': 0.1424,
  ///    'kWh': 529542.5,
  ///    'averagePriceWeightedByVolume': 0.1419
  ///  },
  ///}
  ///```
  Future<List<Map<String, dynamic>>> getBacklogForUtility({
    required Utility utility,
    required Month start,
    required Month end,
  }) async {
    var url = '$rootUrl$servicePath/utility/${utility.toString()}'
        '/start/${start.toIso8601String()}'
        '/end/${end.toIso8601String()}';

    var response = await http.get(Uri.parse(url));
    var data =
        (json.decode(response.body) as List).cast<Map<String, dynamic>>();
    return data;
  }
}
