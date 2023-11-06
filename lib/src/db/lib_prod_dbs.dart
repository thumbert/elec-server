library db.lib_prod_dbs;

import 'package:mongo_dart/mongo_dart.dart';

abstract class DbEnv {}

class DbProd extends DbEnv {
  static String? _connection;

  DbProd({String connection = '127.0.0.1:27017'}) {
    DbProd._connection = connection;
  }

  static final String mongoPort = '27017';
  static final cme = Db('mongodb://${DbProd._connection}/cme');
  static final ieso = Db('mongodb://${DbProd._connection}/ieso');
  static final isoexpress = Db('mongodb://${DbProd._connection}/isoexpress');
  static final isone = Db('mongodb://${DbProd._connection}/isone');
  static final marks = Db('mongodb://${DbProd._connection}/marks');
  static final mis = Db('mongodb://${DbProd._connection}/mis');
  static final nyiso = Db('mongodb://${DbProd._connection}/nyiso');
  static final pjm = Db('mongodb://${DbProd._connection}/pjm');
  static final polygraph = Db('mongodb://${DbProd._connection}/polygraph');
  static final retailSuppliers = Db('mongodb://${DbProd._connection}/retail_suppliers');
  static final riskSystem = Db('mongodb://${DbProd._connection}/risk_system');
  static final utility = Db('mongodb://${DbProd._connection}/utility');
  static final weather = Db('mongodb://${DbProd._connection}/weather');
}
