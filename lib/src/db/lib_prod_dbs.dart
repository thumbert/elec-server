library db.lib_prod_dbs;

import 'package:mongo_dart/mongo_dart.dart';

abstract class DbEnv {}

class DbProd extends DbEnv {
  static String? connection;

  DbProd({String? connection}) {
    connection ??= '127.0.0.1:27017';
    DbProd.connection = connection;
  }

  static final String mongoPort = '27017';
  static final isoexpress = Db('mongodb://${DbProd.connection}/isoexpress');
  static final isone = Db('mongodb://${DbProd.connection}/isone');
  static final marks = Db('mongodb://${DbProd.connection}/marks');
  static final mis = Db('mongodb://${DbProd.connection}/mis');
  static final riskSystem = Db('mongodb://${DbProd.connection}/risk_system');
}
