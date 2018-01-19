library test.isone_energyoffers_test;

import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/api_isone_energyoffers.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


ApiTest(Db db) async {
  var api = new DaEnergyOffers(db);
  test('get stack for one hour', () async {
    await db.open();
    var data = await api.getEnergyOffers('20170701','16');
    print(data);
    //expect(dt, dt2);
    await db.close();
  });
}


main() async {
  initializeTimeZoneSync( getLocationTzdb() );
  Db db = new Db('mongodb://localhost/isoexpress');
  await ApiTest(db);



}
