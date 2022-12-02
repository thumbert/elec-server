library db.utilities.eversource.rate_board;

import 'dart:convert';

import 'package:http/http.dart';

final _config = <Map<String, dynamic>>[
  {
    'utility': 'Eversource',
    'type': 'business',
    'rate': 'Rate 30',
    'query': {
      'customerClass[]': '1206',
      'monthlyUsage': '2000',
      'planType': 'ES Rate 30',
      'planTypeEdc[]': '1191',
    },
  },
  {
    'utility': 'Eversource',
    'type': 'business',
    'rate': 'Rate 35',
    'query': {
      'customerClass[]': '1206',
      'monthlyUsage': '2000',
      'planType': 'ES Rate 35',
      'planTypeEdc[]': '1191',
    },
  },
  {
    'utility': 'Eversource',
    'type': 'residential',
    'rate': '',
    'query': {
      'customerClass[]': '1201',
      'monthlyUsage': '750',
      'planTypeEdc[]': '1191',
    },
  },
  // {
  //   'utility': 'UI',
  //   'type': 'business',
  //   'rate': 'Rate GS',
  //   'fragment': 'customerClass=1206&monthlyUsage=2000&planType=UI%20Rate%20GS&planTypeEdc=1196',
  // },
  // {
  //   'utility': 'UI',
  //   'type': 'business',
  //   'rate': 'Rate GST',
  //   'fragment': 'customerClass=1206&monthlyUsage=2000&planType=UI%20Rate%20GST&planTypeEdc=1196',
  // },
  // {
  //   'utility': 'UI',
  //   'type': 'residential',
  //   'rate': 'Rate R',
  //   'fragment': 'customerClass=1201&monthlyUsage=750&planType=UI%20Rate%20R&planTypeEdc=1196',
  // },
  // {
  //   'utility': 'UI',
  //   'type': 'residential',
  //   'rate': 'Rate RT',
  //   'fragment': 'customerClass=1201&monthlyUsage=750&planType=UI%20Rate%20RT&planTypeEdc=1196',
  // },
];

class RateBoardArchive {
  /// https://energizect.com/rate-board/compare-energy-supplier-rates?customerClass=1201&monthlyUsage=750&planTypeEdc=1191
  Future<List<Map<String, dynamic>>> getCurrentRates() async {
    var allOffers = <Map<String,dynamic>>[];
    for (var one in _config) {
      var url = Uri(
          scheme: 'https',
          host: 'energizect.com',
          path: '/ectr_search_api/offers',
          queryParameters: one['query']);
      var res = await get(url);
      if (res.statusCode != 200) {
        throw StateError('Error downloading data from $url');
      }

      var aux = json.decode(res.body);
      var offers = (aux['results'] as List).cast<Map<String,dynamic>>();
      allOffers.addAll(offers);
    }
    return allOffers;
  }
}



