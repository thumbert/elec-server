library db.curves.curveid;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';

class CurveIdArchive {
  ComponentConfig dbConfig;

  final _mustHaveKeys = <String>{
    'curveId',
    'commodity',  // electricity, ng, etc.
    'unit',       // $/MWh, etc.
    'tzLocation', // America/New_York, etc.
    'buckets'     // ['7x24'], ['5x16', '2x16H', '7x8'], etc.
  };

  /// Keep track of curve details, e.g. region, serviceType, location, children,
  /// and the rule for composing it
  CurveIdArchive({this.dbConfig}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'marks'
      ..collectionName = 'curve_ids';
  }

  mongo.Db get db => dbConfig.db;

  /// Insert/Update a list of documents into the db.
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
      for (var x in data) {
        checkDocument(x);
        await dbConfig.coll.remove({'curveId': x['curveId']});
        await dbConfig.coll.insert(x);
        print('--->  Inserted curveId ${x['curveId']} successfully');
      }
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
    return Future.value(0);
  }

  /// Check if a document is valid.
  void checkDocument(Map<String, dynamic> xs) {
    var keys = xs.keys.toSet();
    if (!keys.containsAll(_mustHaveKeys)) {
      throw 'Missing one of must have keys: $_mustHaveKeys';
    }
  }

  void setup() async {
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'curveId': 1}, unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'region': 1,
      'serviceType': 1,
    });
  }
}
