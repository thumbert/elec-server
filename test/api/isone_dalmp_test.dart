library test.isone_dalmp_test;

import 'dart:io';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/api/isone_dalmp.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


testByRow(db) async {
  DaLmp dalmp = new DaLmp(db);
  var x = dalmp.getHourlyCongestionData(4000);
  await for (var e in x) {
    print(e);
  }
}

testByColumn(db) async {
  DaLmp dalmp = new DaLmp(db);
//  var x = await dalmp.getHourlyDataColumn(4000, 'lmp');
  var x = await dalmp.getHourlyDataColumn(4000, 'congestion');
  print(x);
}


main() async {
  print(getLocationTzdb());
  initializeTimeZoneSync( getLocationTzdb() );

  Db db = new Db('mongodb://localhost/isone_dam');
  await db.open();

//  await testByRow(db);
  await testByColumn(db);

  await db.close();
}
