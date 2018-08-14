library api.sp_peakcontributiondly;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';

@ApiClass(name: 'sp_peakcontributiondly', version: 'v1')
class SpPeakContributionDly {
  DbCollection coll;
  Location location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'sp_peakcontributiondly';

  SpPeakContributionDly(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
  }

  //http://localhost:8080/sp_peakcontributiondly/v1/assetId/2481/start/20180101/end/20180201
  @ApiMethod(path: 'assetId/{assetId}/start/{start}/end/{end}')
  Future<List<Map<String,String>>> peakByAsset(
      String assetId, String start, String end) async {
    List pipeline = [];
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
    var res = coll.aggregateToStream(pipeline);
    return res.toList();
  }

  @ApiMethod(path: 'month/{month}/assetIds/{assetIds}')
  /// enter assetIds comma separated, e.g. 1485,2481
  Future<List<Map<String,String>>> peakByAssets(String month,
      String assetIds) async {
    month = month.replaceAll('-', '');
    Month m = new Month(int.parse(month.substring(0,4)),
          int.parse(month.substring(4,6)));

    List<int> loadIds = assetIds.split(',').map((e) => int.parse(e.trim())).toList();
    List pipeline = [];
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
    var res = coll.aggregateToStream(pipeline);
    return res.toList();
  }


  //http://localhost:8080/sp_peakcontributiondly/v1/start/20180101/end/20180101
  @ApiMethod(path: 'start/{start}/end/{end}')
  Future<List<Map<String,String>>> peakAll(
      String start, String end) async {
    List pipeline = [];
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
    var res = coll.aggregateToStream(pipeline);
    return res.toList();
  }

}
