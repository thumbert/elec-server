import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';

// @ApiClass(name: 'sp_peakcontributiondly', version: 'v1')
class SpPeakContributionDly {
  late mongo.DbCollection coll;
  Location? location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'sp_peakcontributiondly';

  SpPeakContributionDly(mongo.Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  //http://localhost:8080/sp_peakcontributiondly/v1/assetId/2481/start/20180101/end/20180201
  // @ApiMethod(path: 'assetId/{assetId}/start/{start}/end/{end}')
  Future<List<Map<String, String?>>> peakByAsset(
      String assetId, String start, String end) async {
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'Asset ID': {
          '\$eq': int.parse(assetId),
        },
        'Trading Date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'Asset Name': 0,
        'Asset Type': 0,
        'Meter Reader Customer ID': 0,
        'version': 0
      }
    });
    var res = coll.aggregateToStream(pipeline as List<Map<String, Object>>);
    return res.toList() as FutureOr<List<Map<String, String?>>>;
  }

  // @ApiMethod(path: 'month/{month}/assetIds/{assetIds}')

  /// enter assetIds comma separated, e.g. 1485,2481
  Future<List<Map<String, String?>>> peakByAssets(
      String month, String assetIds) async {
    month = month.replaceAll('-', '');
    var m = Month.utc(
        int.parse(month.substring(0, 4)), int.parse(month.substring(4, 6)));

    var loadIds = assetIds.split(',').map((e) => int.parse(e.trim())).toList();
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'Asset ID': {
          '\$in': loadIds,
        },
        'Trading Date': {
          '\$gte': m.startDate.toString(),
          '\$lte': m.endDate.toString(),
        },
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'Asset Name': 0,
        'Asset Type': 0,
        'Meter Reader Customer ID': 0,
        'version': 0
      }
    });
    var res = coll.aggregateToStream(pipeline as List<Map<String, Object>>);
    return res.toList() as FutureOr<List<Map<String, String?>>>;
  }

  //http://localhost:8080/sp_peakcontributiondly/v1/start/20180101/end/20180101
  // @ApiMethod(path: 'start/{start}/end/{end}')
  Future<List<Map<String, String?>>> peakAll(String start, String end) async {
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'Trading Date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'Asset Name': 0,
        'Asset Type': 0,
        'Meter Reader Customer ID': 0,
        'version': 0
      }
    });
    var res = coll.aggregateToStream(pipeline as List<Map<String, Object>>);
    return res.toList() as FutureOr<List<Map<String, String?>>>;
  }
}
