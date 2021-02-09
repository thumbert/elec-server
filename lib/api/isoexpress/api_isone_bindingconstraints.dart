library api.isone_bingingconstraints;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import '../../src/utils/api_response.dart';

@ApiClass(name: 'bc', version: 'v1')
class BindingConstraints {
  DbCollection coll;
  Location _location = getLocation('America/New_York');
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'binding_constraints';

  BindingConstraints(Db db) {
    coll = db.collection(collectionName);
  }

  @ApiMethod(path: 'market/da/start/{start}/end/{end}')
  Future<ApiResponse> apiGetDaBindingConstraintsByDay(
      String start, String end) async {
    var query = where;
    query = query.gte('date', Date.parse(start).toString());
    query = query.lte('date', Date.parse(end).toString());
    query = query.eq('market', 'DA');
    query = query.excludeFields(['_id', 'date', 'market']);
    var res = await coll.find(query).map((Map<String, Object> e) {
      var start = TZDateTime.from(e['hourBeginning'] as DateTime, _location);
      e['hourBeginning'] = start.toString();
      return e;
    }).toList();
    return ApiResponse()..result = json.encode(res);
  }

  @ApiMethod(
      path:
          'market/{market}/constraintname/{constraintName}/start/{start}/end/{end}')
  Future<ApiResponse> apiGetBindingConstraintsByName(
      String market, String constraintName, String start, String end) async {
    var query = where;
    query = query.gte('date', Date.parse(start).toString());
    query = query.lte('date', Date.parse(end).toString());
    query = query.eq('Constraint Name', constraintName);
    query = query.eq('market', market.toUpperCase());
    query = query.excludeFields(['_id', 'date', 'market']);
    var res = await coll.find(query).map((Map<String, Object> e) {
      var start = TZDateTime.from(e['hourBeginning'] as DateTime, _location);
      e['hourBeginning'] = start.toString();
      return e;
    }).toList();
    return ApiResponse()..result = json.encode(res);
  }
}
