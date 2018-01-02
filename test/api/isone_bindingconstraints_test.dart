library test.isone_bindingconstraints_test;

import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/api_isone_bindingconstraints.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


ApiBindingConstraintsTest(Db db) async {
  var api = new BindingConstraints(db);
  test('get constraints data for 2 days', () async {
    await db.open();
    var data = await api.apiGetDaBindingConstraintsByDay(
      '20170101', '20170102');
    expect(data.length, 44);
    await db.close();
  });
}


main() async {
  initializeTimeZoneSync( getLocationTzdb() );
  Db db = new Db('mongodb://localhost/isoexpress');
  await ApiBindingConstraintsTest(db);
}
