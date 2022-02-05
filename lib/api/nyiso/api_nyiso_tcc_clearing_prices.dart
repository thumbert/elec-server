library api.api_ftr_clearing_prices;

import 'dart:async';
import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiNyisoTccClearingPrices {
  late DbCollection coll;
  String collectionName = 'tcc_clearing_prices';
  final Location location = getLocation('America/New_York');
  final String rootUrl;

  ApiNyisoTccClearingPrices(Db db, {this.rootUrl = 'http://localhost:8080'}) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    //http://localhost:8080/nyiso/tcc_clearing_prices/v1/ptid/4000
    router.get('/ptid/<ptid>', (Request request, String ptid) async {
      var res = await clearingPricesPtid(int.parse(ptid));
      return Response.ok(json.encode(res), headers: headers);
    });

    //http://localhost:8080/nyiso/tcc_clearing_prices/v1/auction/G22
    router.get('/auction/<auctionName>',
        (Request request, String auctionName) async {
      var res = await clearingPricesAuction(auctionName);
      return Response.ok(json.encode(res), headers: headers);
    });

    // router.get('/cpsp/source/<sourcePtid>/sink/<sinkPtid>/auctions/<auctions>',
    //     (Request request, String sourcePtid, String sinkPtid,
    //         String auctions) async {
    //   var res =
    //       await cpsp(int.parse(sourcePtid), int.parse(sinkPtid), auctions);
    //   return Response.ok(json.encode(res), headers: headers);
    // });

    return router;
  }

  /// Return a list of Map of this form
  /// ```
  /// {
  ///   'auctionName': 'X21-6M-R5',
  ///   'cp': <num>,
  /// }
  /// ```
  /// The clearing price is in $/MWh, ATC
  Future<List<Map<String, dynamic>>> clearingPricesPtid(int ptid) async {
    var query = where.eq('ptid', ptid).excludeFields(['_id', 'ptid']);
    return coll.find(query).toList();
  }

  Future<List<Map<String, dynamic>>> clearingPricesAuction(
      String auctionName) async {
    var query = where;
    query = query.eq('auctionName', auctionName);
    query = query.excludeFields(['_id', 'auctionName']);
    return coll.find(query).toList();
  }

  /// Get the Clearing prices and Settle prices for this path, for all the
  /// auctions requested.
  /// <p>[auctions] is a comma separated list of auction names, e.g.
  /// 'F19-1Y-R1,F19,X19-boppV19,U19,M18'
  ///
  // Future<List<Map<String, dynamic>>> cpsp(
  //     int sourcePtid, int sinkPtid, String auctions) async {
  //   var _auctions =
  //       auctions.split(',').map((e) => FtrAuction.parse(e)).toList();
  //
  //   var res = <Map<String, dynamic>>[];
  //
  //   /// get the cleared and settle prices
  //   var path =
  //       FtrPath(sourcePtid, sinkPtid, NewYorkIso.bucket7x24, rootUrl: rootUrl);
  //   var cpsp = await path.historicalClearedVsSettle(auctions: _auctions);
  //
  //   for (var auction in cpsp.keys) {
  //     var sp = cpsp[auction]!['settlePrice']!;
  //     var cp = cpsp[auction]!['clearedPrice']!;
  //     res.add({
  //       'Auction': auction.name,
  //       'Cleared Price': cp.isNaN ? null : cp,
  //       'Settle Price': sp.isNaN ? null : sp,
  //     });
  //   }
  //   return res;
  // }
}
