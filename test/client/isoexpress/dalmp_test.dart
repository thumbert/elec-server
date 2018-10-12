library test.isone_dalmp_test;

import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/common_enums.dart';
import 'package:elec_server/client/isoexpress/dalmp.dart';

tests() async {
  Location location = getLocation('US/Eastern');
  var api = DalmpApi(new Client());
  group('API DA Hourly prices:', () {
    test('get hourly lmp data for 2 days', () async {
      var interval = Interval(new TZDateTime(location, 2017, 1, 1),
          new TZDateTime(location, 2017, 1, 3));
      var aux = await api.getHourlyData(LmpComponent.lmp, 4000, interval);
      expect(aux.length, 48);
      expect(aux.first, new IntervalTuple(new Hour.beginning(TZDateTime(location, 2017)), 35.12));
    });

    test('get daily lmp prices for peak bucket', () async {
      var interval = Interval(new TZDateTime(location, 2017, 7, 1),
          new TZDateTime(location, 2017, 7, 8));
      var res = await api.getDailyBucketPrice(
          LmpComponent.lmp, 4000, interval, IsoNewEngland.bucket5x16);
      expect(res.length, 4);
      expect(res.first,
          IntervalTuple(Date(2017, 7, 3, location: location), 35.225));
    });
    test('get daily lmp prices for flat bucket', () async {
      var interval = Interval(new TZDateTime(location, 2017, 7, 1),
          new TZDateTime(location, 2017, 7, 8));
      var res = await api.getDailyBucketPrice(
          LmpComponent.lmp, 4000, interval, IsoNewEngland.bucket7x24);
      expect(res.length, 7);
    });
    test('get monthly lmp prices for flat bucket', () async {
      var interval = Interval(new TZDateTime(location, 2017, 7, 1),
          new TZDateTime(location, 2017, 9, 1));
      var res = await api.getMonthlyBucketPrice(LmpComponent.lmp, 4000,
          interval, IsoNewEngland.bucket7x24);
      expect(res.length, 2);
      expect(res.first, IntervalTuple(Month(2017, 7), 27.604422043010757));
    });
  });
}

main() async {
  await initializeTimeZone();
  await tests();
}
