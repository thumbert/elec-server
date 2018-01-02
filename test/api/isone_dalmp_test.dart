library test.isone_dalmp_test;

import 'dart:io';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/api_isone_dalmp.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


ApiDaLmpHourlyTest(Db db) async {
  var api = new DaLmp(db);
  test('get lmp data for 2 days', () async {
    await db.open();
    var data = await api.getHourlyData(4000, 'lmp',
        startDate: new Date(2017,1,1), endDate: new Date(2017,1,2)).toList();
    expect(data.length, 2);
    await db.close();
  });
}


main() async {
  initializeTimeZoneSync( getLocationTzdb() );
  Db db = new Db('mongodb://localhost/isoexpress');
  await ApiDaLmpHourlyTest(db);

}
