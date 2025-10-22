import 'dart:async';
import 'dart:convert';
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

    //http://localhost:8080/nyiso/tcc_clearing_prices/v1/ptid/61752
    router.get('/ptid/<ptid>', (Request request, String ptid) async {
      var res = await clearingPricesPtid(int.parse(ptid));
      return Response.ok(json.encode(res), headers: headers);
    });

    //http://localhost:8080/nyiso/tcc_clearing_prices/v1/ptids/61752,61758
    router.get('/ptids/<ptids>', (Request request, String ptids) async {
      var ptidSplit = ptids.split(',').map((e) => int.parse(e)).toList();
      var res = await clearingPricesSeveralPtids(ptidSplit);
      return Response.ok(json.encode(res), headers: headers);
    });

    //http://localhost:8080/nyiso/tcc_clearing_prices/v1/auction/G22
    router.get('/auction/<auctionName>',
        (Request request, String auctionName) async {
      var res = await clearingPricesAuction(auctionName);
      return Response.ok(json.encode(res), headers: headers);
    });

    /// Get the auction names that are in the database, lexically sorted
    router.get('/auctions', (Request request) async {
      var aux = await coll.distinct('auctionName');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    return router;
  }

  /// Return a list of Map of this form
  /// ```
  /// {
  ///   'auctionName': 'X21-6M-R5',
  ///   'bucket': '7x24',
  ///   'clearingPriceHour': 3.98567,
  /// }
  /// ```
  /// The clearing price is in $/MWh, ATC
  Future<List<Map<String, dynamic>>> clearingPricesPtid(int ptid) async {
    var query = where.eq('ptid', ptid).excludeFields(['_id', 'ptid']);
    return coll.find(query).map((e) {
      e['bucket'] = '7x24';
      return e;
    }).toList();
  }

  /// Return a list of Map of this form
  /// ```
  /// {
  ///   'ptid': 61752,
  ///   'auctionName': 'X21-6M-R5',
  ///   'bucket': '7x24',
  ///   'clearingPriceHour': 3.98567,
  /// }, ...
  /// ```
  /// The clearing price is in $/MWh, ATC
  Future<List<Map<String, dynamic>>> clearingPricesSeveralPtids(
      List<int> ptids) async {
    var query = where.oneFrom('ptid', ptids).excludeFields(['_id']);
    return coll.find(query).map((e) {
      e['bucket'] = '7x24';
      return e;
    }).toList();
  }

  /// Return a list of Map of this form
  /// ```
  /// {
  ///   'ptid': 61752,
  ///   'auctionName': 'X21-6M-R5',
  ///   'bucket': '7x24',
  ///   'clearingPriceHour': 3.98567,
  /// }, ...
  /// ```
  /// The clearing price is in $/MWh, ATC
  Future<List<Map<String, dynamic>>> clearingPricesAuction(
      String auctionName) async {
    var query = where
        .eq('auctionName', auctionName)
        .excludeFields(['_id', 'auctionName']);
    return coll.find(query).map((e) {
      e['bucket'] = '7x24';
      return e;
    }).toList();
  }
}
