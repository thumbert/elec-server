library test.isone_dalmp_test;

import 'dart:convert';
import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/api_isone_dalmp.dart';


apiTest() async {
  Db db;
  DaLmp api;
  Location location = getLocation('US/Eastern');
  setUp(() async {
    db = new Db('mongodb://localhost/isoexpress');
    api = new DaLmp(db);
    await db.open();
  });
  tearDown(() async {
    await db.close();
  });
  group('API DA Hourly prices:', (){
    test('get lmp data for 2 days', () async {
      var aux = await api.getHourlyData(4000, new Date(2017,1,1),
          new Date(2017,1,2), 'lmp');
      expect(aux.length, 48);
      expect(aux.first, {
        'hourBeginning': '2017-01-01 00:00:00.000-0500',
        'lmp': 35.12,
      });
    });
    test('get daily lmp prices by peak bucket', () async {
      var res = await api.getDailyBucketPrice('lmp', 4000,
          '2017-07-01', '2017-07-07', '5x16');
      var data = json.decode(res.result);
      expect(data.length, 4);
      expect(data.first, {'date': '2017-07-03', 'lmp': 35.225});
    });

    test('get daily lmp prices by flat bucket', () async {
      var res = await api.getDailyBucketPrice('lmp', 4000,
          '2017-07-01', '2017-07-07', 'flat');
      var data = json.decode(res.result);
      expect(data.length, 7);
    });
    test('get monthly lmp prices by flat bucket', () async {
      var res = await api.getMonthlyBucketPrice('lmp', 4000,
          '2017-07-01', '2017-08-01', 'flat');
      var data = json.decode(res.result);
      expect(data.length, 2);
      expect(data.first, {'month': '2017-07', 'lmp': 27.604422043010757});
    });

  });

}


main() async {
  await initializeTimeZone();
  await apiTest();

}
