import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SystemDemand {
  late DbCollection coll;
  late Location _location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'system_demand';

  SystemDemand(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/market/<market>/start/<start>/end/<end>',
        (Request request, String market, String start, String end) async {
      var aux = await apiGetSystemDemand(market, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// http://localhost:8080/system_demand/v1/market/da/start/20170101/end/20170101
  Future<List<Map<String, dynamic>>> apiGetSystemDemand(
      String market, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var res = [];
    var data = _getData(market.toUpperCase(), startDate, endDate);
    String? columnName;
    if (market.toUpperCase() == 'DA') {
      columnName = 'Day-Ahead Cleared Demand';
    } else if (market.toUpperCase() == 'RT') {
      columnName = 'Total Load';
    }
    await for (var e in data) {
      for (var i = 0; i < e['hourBeginning'].length; i++) {
        res.add({
          'hourBeginning':
              TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          columnName: e[columnName][i]
        });
      }
    }
    return res as FutureOr<List<Map<String, dynamic>>>;
  }

  /// Workhorse to extract the data ...
  /// returns one element for each day
  Stream _getData(String market, Date startDate, Date endDate) {
    var pipeline = [];
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
    return coll.aggregateToStream(pipeline as List<Map<String, Object>>);
  }
}
