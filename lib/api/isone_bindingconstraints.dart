library api.isone_bingingconstraints;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';

/**
 * Get start/end date of the data
 *   db.binding_constraints.aggregate([{$group: {_id: null, minHour:{$min: '$hourEnding'}, maxHour: {$max: '$hourEnding'}}}])
 * Get all distinct constraints
 *   db.binding_constraints.distinct('ConstraintName').sort('ConstraintName', 1)
 * Get binding constraints after a date
 *   db.binding_constraints.find({hourEnding: {$gte: new Date("2015-03-05T00:00:00.000Z")}})
 */

@ApiClass(name: 'bc', version: 'v1')
class BindingConstraints {
  DbCollection coll;
  Location _location = getLocation('US/Eastern');
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'binding_constraints';

  BindingConstraints(Db db) {
    coll = db.collection(collectionName);
  }

  @ApiMethod(path: 'market/da/start/{start}/end/{end}')
  Future<List<Map<String, String>>> apiGetDaBindingConstraintsByDay(
      String start, String end) async {
    SelectorBuilder query = where;
    query = query.gte('date', Date.parse(start).toString());
    query = query.lte('date', Date.parse(end).toString());
    query = query.eq('market', 'DA');
    query = query.excludeFields(['_id', 'Hour Ending', 'date', 'market']);
    return await coll.find(query).map((Map e) {
      var start = new TZDateTime.from(e['hourBeginning'], _location);
      e['hourBeginning'] = start.toString();
      return e;
    }).toList();
  }

  @ApiMethod(path: 'market/{market}/constraintname/{constraintName}')
  Future<List<Map<String, String>>> apiGetDaBindingConstraintsByName(
      String market, String constraintName) async {
    SelectorBuilder query = where;
    query = query.eq('Constraint Name', constraintName);
    query = query.eq('market', market.toUpperCase());
    query = query.excludeFields(['_id', 'Hour Ending', 'date', 'market']);
    return await coll.find(query).map((Map e) {
      var start = new TZDateTime.from(e['hourBeginning'], _location);
      e['hourBeginning'] = start.toString();
      return e;
    }).toList();
  }


}




//    if (constraintNames != null && constraintNames.isNotEmpty) query =
//        query.oneFrom('ConstraintName', constraintNames);
