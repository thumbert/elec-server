library db.curves.curveid;

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';
import 'package:intl/intl.dart';

class CurveIdArchive {
  ComponentConfig dbConfig;
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');
  final _equality = const ListEquality();

  /// Keep track of curve details, e.g. region, serviceType, location, children,
  /// and the rule for composing it
  CurveIdArchive({this.dbConfig}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'marks'
      ..collectionName = 'curve_ids';
  }

  mongo.Db get db => dbConfig.db;

  /// Insert a list of documents into the db.
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
          await dbConfig.coll.insertAll(data);
          print('--->  Inserted curveIds successfully');
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
    return Future.value(0);
  }

  void setup() async {
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'curveId': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {
          'region': 1,
          'serviceType': 1,
    });
  }
}
