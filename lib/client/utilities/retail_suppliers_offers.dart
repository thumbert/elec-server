import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:http/http.dart' as http;

class RetailSuppliersOffers {
  RetailSuppliersOffers(this.client, {this.rootUrl = 'http://localhost:8000'});

  final http.Client client;
  final String rootUrl;
  final String servicePath = '/retail_suppliers/v1/';

  /// Get the current offers as of a given date.  All offers need to be for one
  /// 'state' only e.g. 'CT' (don't mix states).
  ///
  static List<RetailSupplyOffer> getCurrentOffers(
      Iterable<RetailSupplyOffer> xs, Date asOfDate) {
    /// keep only offers that are between postedOnDate and lastDateOnWebsite
    var aux = xs
        .where((e) =>
            e.lastDateOnWebsite.value >= asOfDate.value &&
            e.offerPostedOnDate.value <= asOfDate.value)
        .toList();

    // /// group by
    // var groups = groupBy(
    //     aux,
    //     (RetailSupplyOffer e) => Tuple2(
    //         Tuple6(e.region, e.state, e.utility, e.accountType, e.offerType,
    //             e.supplierName),
    //         Tuple2(e.countOfBillingCycles, e.minimumRecs)));
    //
    // /// Sort within the groups by offer posted date and pick the last one(s)
    // /// Note that there could be several offers with all fields identical
    // /// except for the rate, but may have a different incentive or fees.
    // var res = <RetailSupplyOffer>[];
    // for (var es in groups.values) {
    //   es.sort((a, b) => -a.offerPostedOnDate.compareTo(b.offerPostedOnDate));
    //   res.addAll(
    //       es.where((e) => e.offerPostedOnDate == es.first.offerPostedOnDate));
    // }

    return aux;
  }

  /// Return the list of offers posted between a start/end date.
  /// [term] corresponds to when the offer was placed not the duration of the
  /// contract.
  ///
  Future<List<RetailSupplyOffer>> getOffers(
      {required String region,
      required String state,
      required Term term}) async {
    var url =
        '$rootUrl${servicePath}offers/region/$region/state/$state/start/${term.startDate}/end/${term.endDate}';

    var response = await client.get(Uri.parse(url));
    var xs = json.decode(response.body) as List;

    return xs.map((e) => RetailSupplyOffer.fromMongo(e)).toList();
  }
}
