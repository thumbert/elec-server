library client.utilities.retail_suppliers_offers;

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

class RetailSuppliersOffers {
  RetailSuppliersOffers(this.client, {this.rootUrl = 'http://localhost:8000'});

  final http.Client client;
  final String rootUrl;
  final String servicePath = '/retail_suppliers/v1/';

  /// Get the current offers as of a given date
  static List<RetailSupplyOffer> getCurrentOffers(Iterable<RetailSupplyOffer> xs, Date asOfDate) {
    /// keep only offers that are before asOfDate
    var aux = xs.whereNot((e) => e.offerPostedOnDate.isAfter(asOfDate));
    /// group by
    var groups = groupBy(aux, (RetailSupplyOffer e) =>
        Tuple2(Tuple6(e.region, e.state, e.utility, e.accountType, e.offerType, e.supplierName),
            Tuple3(e.countOfBillingCycles, e.minimumRecs, e.offerType)));

    /// Sort within the groups by offer posted date and pick the last one(s)
    /// Note that there could be several offers with similar everything
    /// except for the rate, but may have a different incentive or fees.
    var res = <RetailSupplyOffer>[];
    for (var es in groups.values) {
      es.sort((a,b) => -a.offerPostedOnDate.compareTo(b.offerPostedOnDate));
      res.addAll(es.where((e) => e.offerPostedOnDate == es.first.offerPostedOnDate));
    }

    return res;
  }

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