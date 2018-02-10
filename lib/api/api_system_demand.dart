library api.system_demand;


import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_cleared_demand_hourly.dart';


@ApiClass(name: 'system_demand', version: 'v1')
class SystemDemand {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'system_demand';

  DaLmp(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/dalmp/v1/byrow/congestion/ptid/4000/start/20170101/end/20170101
  @ApiMethod(path: 'byrow/{component}/ptid/{ptid}/start/{start}/end/{end}')
  Future<List<Map<String, String>>> apiGetHourlyDataByRow(String component,
      int ptid, String start, String end) {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    return getHourlyDataRow(ptid, component,
        startDate: startDate, endDate: endDate);
  }


  /// Workhorse to extract the data ...
  /// returns one element for each day
  Stream getHourlyData(int ptid, String component,
      {Date startDate, Date endDate}) {
    List pipeline = [];
    Map match = {
      'ptid': {'\$eq': ptid}
    };
    Map date = {};
    if (startDate != null) date['\$gte'] = startDate.toString();
    if (endDate != null) date['\$lt'] = endDate.add(1).toString();
    if (date.isNotEmpty) match['date'] = date;

    Map project;
    if (component == 'lmp') {
      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$lmp'};
    } else if (component == 'congestion') {
      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$congestion'};
    } else if (component == 'marginal_loss') {
      project = {'_id': 0, 'hourBeginning': 1, 'price': '\$marginal_loss'};
    }
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    return coll.aggregateToStream(pipeline);
  }
}