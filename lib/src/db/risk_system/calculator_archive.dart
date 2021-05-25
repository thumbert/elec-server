library db.risk_system.calculator_archive;

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';

class CalculatorArchive {
  late ComponentConfig dbConfig;

  static final _mustHaveKeys = <String>{
    'userId',
    'calculatorName', //
    'calculatorType', // elec_swap, elec_daily_option, etc.
    'buy/sell',
    'term',
    'comments',
    'legs',
  };

  final log = Logger('CalculatorArchive');

  CalculatorArchive({ComponentConfig? dbConfig}) {
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1',
          dbName: 'risk_system',
          collectionName: 'calculators');
    }
  }

  mongo.Db? get db => dbConfig.db;

  /// Insert one calculator at a time in the collection
  Future<int> insertData(Map<String, dynamic> data) async {
    try {
      data.remove('asOfDate'); // don't save that to the db
      isValidDocument(data);
      await dbConfig.coll.remove({
        'userId': data['userId'],
        'calculatorName': data['calculatorName'],
        'calculatorType': data['calculatorType'],
      });
      await dbConfig.coll.insert(data);
      log.info(
          '--->  Inserted calculator ${data['calculatorName']} successfully');
    } catch (e) {
      log.severe('XXX ' + e.toString());
      return Future.value(1);
    }
    return Future.value(0);
  }

  /// Check if a document is valid.
  static bool isValidDocument(Map<String, dynamic> xs) {
    var keys = xs.keys.toSet();
    if (!keys.containsAll(_mustHaveKeys)) {
      print('Missing one of must have keys: $_mustHaveKeys');
      return false;
    }
    return true;
  }

  void setup() async {
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'userId': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'userId': 1,
          'calculatorName': 1,
        },
        unique: true);
  }
}
