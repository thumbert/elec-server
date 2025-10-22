import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiFwdResAuctionResults {
  late DbCollection coll;
  String collectionName = 'fwdres_auction_results';

  ApiFwdResAuctionResults(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all the auction results.  Data is small enough you can get it all
    /// at once.
    router.get('/all', (Request request) async {
      var aux = await getAll();
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Each element in this form
  /// ```
  /// {
  ///   'auctionName': 'Summer 20',
  ///   'reserveZoneId': 7000,
  ///   'reserveZoneName': 'ROS',
  ///   'product': 'TMNSR',
  ///   'mwOffered': 2214.46,
  ///   'mwCleared': 1297.83,
  ///   'clearingPrice': 1249.0,
  ///   'proxyPrice': 1249.0,
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getAll() async {
    var query = where..excludeFields(['_id']);
    return coll.find(query).toList();
  }
}
