library test.isone_bindingconstraints_test;

import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/api/api_isone_bindingconstraints.dart';

apiTest() async {
  group('API binding constraint tests:', (){
    Db db = new Db('mongodb://localhost/isoexpress');
    BindingConstraints api;
    setUp(() async {
      api = new BindingConstraints(db);
      await db.open();
    });
    tearDown(() async {
      await db.close();
    });
    test('get constraints data for 2 days', () async {
      var data = await api.apiGetDaBindingConstraintsByDay(
          '20170101', '20170102');
      expect(data.length, 44);
    });
    test('get SHFHGE constraint data', () async {
      var data = await api.apiGetDaBindingConstraintsByName('DA',
          'SHFHGE');
      expect(data.length > 100, true);
//      data.forEach(print);
    });

  });

}


main() async {
  await initializeTimeZone();

  await apiTest();

}
