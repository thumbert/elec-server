library test.isone_dalmp_test;

import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/api_isone_dalmp.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


ApiDaLmpHourlyTest() async {
  Db db;
  DaLmp api;
  setUp(() async {
    db = new Db('mongodb://localhost/isoexpress');
    api = new DaLmp(db);
    await db.open();
  });
  tearDown(() async {
    await db.close();
  });
  group('API DA Hourly prices', (){
    test('get lmp data for 2 days', () async {
      var data = await api.getHourlyData(4000, 'lmp',
          startDate: new Date(2017,1,1), endDate: new Date(2017,1,2)).toList();
      expect(data.length, 2);
    });

    test('get daily lmp prices by peak bycket', () async {
      var data = await api.apiGetDailyBucketPrice('lmp', 4000,
          '2017-07-01', '2017-07-07', '5x16');
      expect(data.length, 4);
      expect(data.first, {'date': '2017-07-03', 'lmp': 35.225});
    });

    test('get daily lmp prices by flat bycket', () async {
      var data = await api.apiGetDailyBucketPrice('lmp', 4000,
          '2017-07-01', '2017-07-07', 'flat');
      expect(data.length, 7);
    });


  });

}


main() async {
  initializeTimeZoneSync( getLocationTzdb() );
  await ApiDaLmpHourlyTest();

}
