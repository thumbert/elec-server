library api.system_demand;

import 'dart:convert';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'system_demand', version: 'v1')
class SystemDemand {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'system_demand';

  SystemDemand(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/system_demand/v1/market/da/start/20170101/end/20170101
  @ApiMethod(path: 'market/{market}/start/{start}/end/{end}')
  Future<ApiResponse> apiGetSystemDemand(
      String market, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    List res = [];
    var data = _getData(market.toUpperCase(), startDate, endDate);
    String columnName;
    if (market.toUpperCase() == 'DA')
      columnName = 'Day-Ahead Cleared Demand';
    else if (market.toUpperCase() == 'RT')
      columnName = 'Total Load';
    await for (var e in data) {
      for (int i = 0; i < e['hourBeginning'].length; i++) {
        res.add({
          'hourBeginning':
              TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          columnName: e[columnName][i]
        });
      }
    }
    return ApiResponse()..result = json.encode(res);
  }

  /// Workhorse to extract the data ...
  /// returns one element for each day
  Stream _getData(String market, Date startDate, Date endDate) {
    List pipeline = [];
    pipeline.add({
      '\$match': {
        'market': {'\$eq': market},
        'date': {
          '\$gte': startDate.toString(),
          '\$lte': endDate.toString(),
        },
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'market': 0,
      }
    });
    return coll.aggregateToStream(pipeline);
  }
}
