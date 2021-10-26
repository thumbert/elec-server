library api.isone_monthly_ncpc_asset;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';

class MonthlyNcpcAsset {
  late DbCollection coll;
  late Location _location;
  String collectionName = 'monthly_ncpc_asset';

  MonthlyNcpcAsset(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all the assets between a start/end month
    router.get('/all/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await apiGetAllAssets(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get one asset between a start/end month
    router.get('/assetId/<assetId>/start/<start>/end/<end>',
        (Request request, String assetId, String start, String end) async {
      var aux = await apiGetAsset(assetId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> apiGetAllAssets(
      String startMonth, String endMonth) async {
    var query = where
      ..gte('month', Month.parse(startMonth).toString())
      ..lte('month', Month.parse(endMonth).toString())
      ..excludeFields(['_id']);

    return coll.find(query).toList();
  }

  Future<List<Map<String, dynamic>>> apiGetAsset(
      String assetId, String startMonth, String endMonth) async {
    var query = where
      ..eq('assetId', int.parse(assetId))
      ..gte('month', Month.parse(startMonth).toString())
      ..lte('month', Month.parse(endMonth).toString())
      ..excludeFields(['_id']);
    return coll.find(query).toList();
  }
}
