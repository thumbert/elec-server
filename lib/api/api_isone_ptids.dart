import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';

@ApiClass(name: 'ptids', version: 'v1')
class ApiPtids {
  DbCollection coll;
  String collectionName = 'pnode_table';

  ApiPtids(Db db) {
    coll = db.collection(collectionName);
  }

  @ApiMethod(path: 'current')
  Future<List<Map<String, String>>> apiPtidTableCurrent() async {
    SelectorBuilder query = where;
    String last = await getAvailableAsOfDates().then((List days) => days.last);
    query = query.eq('asOfDate', last);
    query = query.excludeFields(['_id', 'asOfDate']);
    return await coll.find(query).toList();
  }

  @ApiMethod(path: 'asofdate/{asOfDate}')
  Future<List<Map<String, String>>> apiPtidTableAsOfDate(
      String asOfDate) async {
    Date asOf = Date.parse(asOfDate);
    var days = await getAvailableAsOfDates()
        .then((List days) => days.map((e) => Date.parse(e)));
    Date last =
    days.firstWhere((e) => !e.isBefore(asOf), orElse: () => days.last);
    SelectorBuilder query = where;
    query = query.eq('asOfDate', last.toString());
    query = query.excludeFields(['_id', 'asOfDate']);
    return await coll.find(query).toList();
  }

  @ApiMethod(path: 'dates')
  Future<List<String>> getAvailableAsOfDates() async {
    Map data = await coll.distinct('asOfDate');
    List<String> days = data['values'];
    days.sort((a, b) => a.compareTo(b));
    return days;
  }
}


