library api.utilities.api_retail_suppliers_offers;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';

class ApiRetailSuppliersOffers {
  late DbCollection coll;
  String collectionName = 'historical_offers';

  ApiRetailSuppliersOffers(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all offers for a region between a start and end date
    router.get('/offers/region/<region>/state/<state>/start/<start>/end/<end>',
        (Request request, String region, String state, String start, String end) async {
      var aux = await getOffersForRegionState(region.toUpperCase(), state.toUpperCase(),
          Date.parse(start, location: UTC), Date.parse(end, location: UTC));
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Return offers for one region
  Future<List<Map<String, dynamic>>> getOffersForRegionState(
      String region, String state, Date? startDate, Date? endDate) async {
    var query = where
      ..eq('region', region.toUpperCase())
      ..eq('state', state.toUpperCase());

    var variable = state == 'CT' ? 'offerPostedOnDate' : 'firstDateOnWebsite';
    if (startDate != null) {
      query = query.lte(variable, endDate.toString());
    }
    if (endDate != null) {
      query = query.gte('lastDateOnWebsite', startDate.toString());
    }
    query = query
      ..fields([
        'offerId',
        'region',
        'state',
        'loadZone',
        'utility',
        'accountType',
        'rateClass',
        'countOfBillingCycles',
        'minimumRecs',
        'offerType',
        'rate',
        'rateUnit',
        'supplierName',
        'planFees',
        'planFeatures',
        'offerPostedOnDate',
        'firstDateOnWebsite',
        'lastDateOnWebsite',
      ])
      ..excludeFields(['_id']);
    var xs = await coll.find(query).toList();
    return xs;
  }
}
