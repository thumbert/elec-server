library client.utilities.retail_suppliers_offers;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:http/http.dart' as http;

class RetailSuppliersOffers {
  RetailSuppliersOffers(this.client, {this.rootUrl = 'http://localhost:8000'});

  final http.Client client;
  final String rootUrl;
  final String servicePath = '/retail_suppliers/v1/';

  /// Return the list of offers for one region between a start/end date.
  Future<List<RetailSupplyOffer>> getOffersForRegionTerm(
      String region, Term term) async {
    var url =
        '$rootUrl${servicePath}offers/region/$region/start/${term.startDate}/end/${term.endDate}';

    var response = await client.get(Uri.parse(url));
    var xs = json.decode(response.body) as List;

    return xs.map((e) => RetailSupplyOffer.fromMongo(e)).toList();
  }
}
