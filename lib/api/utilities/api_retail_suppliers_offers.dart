library api.utilities.api_retail_suppliers_offers;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
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

    /// Get all offers for a region
    router.get('/offers/region/<region>',
        (Request request, String region) async {
      var aux = await getOffersForRegion(region, null, null);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get all offers for a region between a start and end date
    router.get('/offers/region/<region>/start/<start>/end/<end>',
        (Request request, String region, String start, String end) async {
      var aux = await getOffersForRegion(region,
          Date.parse(start, location: UTC), Date.parse(end, location: UTC));
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Return offers for one region
  Future<List<Map<String, dynamic>>> getOffersForRegion(
      String region, Date? startDate, Date? endDate) async {
    var query = where..eq('region', region.toUpperCase());
    if (startDate != null) {
      query = query.gte('offerPostedOnDate', startDate.toString());
    }
    if (endDate != null) {
      query = query.lte('offerPostedOnDate', endDate.toString());
    }
    query = query
      ..fields([
        'offerId',
        'region',
        'state',
        'loadZone',
        'utility',
        'accountType',
        'countOfBillingCycles',
        'minimumRecs',
        'offerType',
        'rate',
        'rateUnit',
        'supplierName',
        'offerPostedOnDate',
      ])
      ..excludeFields(['_id']);
    var xs = await coll.find(query).toList();
    return xs;
  }
}
