library db.config;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';

import '../utils/timezone_utils.dart';


class ComponentConfig {
  Db _db;
  /// name of the mongo database
  String dbName;
  /// name of the computer that houses the collection
  String host;
  /// name of the mongo collection
  String collectionName;
  /// location on hard drive where external data is held
  //String DIR;
  /// get the mongo database
  Db get db {
    if (_db == null) _db = new Db('mongodb://$host/$dbName');
    return _db;
  }
  DbCollection get coll => db.collection(collectionName);
}


abstract class Config {
  String configName; // prod, test, etc.
  String host;
  String tzdb;

  ComponentConfig isone_binding_constraints_da;
  ComponentConfig isone_dam_lmp_hourly;

  Future open() async {
    initializeTimeZoneSync(tzdb);
    await isone_dam_lmp_hourly.db.open();
    await isone_binding_constraints_da.db.open();
  }

  Future close() async {
    await isone_dam_lmp_hourly.db.close();
    await isone_binding_constraints_da.db.close();
  }

}

