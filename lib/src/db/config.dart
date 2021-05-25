library db.config;

import 'package:mongo_dart/mongo_dart.dart';

class ComponentConfig {
  Db? _db;
  /// name of the mongo database
  final String dbName;
  /// name of the computer that houses the collection
  final String host;
  /// name of the mongo collection
  final String collectionName;

  /// A MongoDb configuration for a specific collection.
  ComponentConfig({required this.host, required this.dbName,
    required this.collectionName});

  /// get the mongo database
  Db get db {
    _db ??= Db('mongodb://$host/$dbName');
    return _db!;
  }

  DbCollection get coll => db.collection(collectionName);
}

