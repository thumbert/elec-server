import 'dart:async';

import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'ptids', version: 'v1')
class ApiPtids {
  DbCollection coll;
  String collectionName = 'pnode_table';

  ApiPtids(Db db) {
    coll = db.collection(collectionName);
  }

  @ApiMethod(path: 'current')
  Future<ApiResponse> apiPtidTableCurrent() async {
    var last = await getAvailableAsOfDates().then((List days) => days.last);
    var query = where
      ..eq('asOfDate', last)
      ..excludeFields(['_id', 'asOfDate']);
    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }

  @ApiMethod(path: 'asofdate/{asOfDate}')
  Future<ApiResponse> apiPtidTableAsOfDate(String asOfDate) async {
    var asOf = Date.parse(asOfDate);
    var days = await getAvailableAsOfDates()
        .then((List days) => days.map((e) => Date.parse(e)));
    var last =
        days.firstWhere((e) => !e.isBefore(asOf), orElse: () => days.last);
    var query = where
      ..eq('asOfDate', last.toString())
      ..excludeFields(['_id', 'asOfDate']);
    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }

  @ApiMethod(path: 'ptid/{ptid}')
  /// Show the days when this ptid is in the database.  Nodes are
  /// retired from time to time.
  Future<ApiResponse> apiPtid(int ptid) async {
    var query = where
      ..eq('ptid', ptid)
      ..fields(['asOfDate'])
      ..excludeFields(['_id']);
    var data = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(data);
  }


  @ApiMethod(path: 'dates')
  Future<List<String>> getAvailableAsOfDates() async {
    Map data = await coll.distinct('asOfDate');
    var days = (data['values'] as List).cast<String>();
    days.sort((a, b) => a.compareTo(b));
    return days;
  }
}

