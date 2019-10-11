library test.client.isoexpress.dalmp;

import 'dart:math';

import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:dama/dama.dart';
import 'package:elec/src/common_enums.dart';
import 'package:elec_server/client/isoexpress/dalmp.dart';

tests(String rootUrl) async {
  group('DAM prices client tests: ', () {
    var location = getLocation('US/Eastern');
    Client client = Client();
    var api = DaLmp(client, rootUrl: rootUrl);

    test('get daily peak price between two dates', () async {
      var data = await api.getDailyLmpBucket(4000, LmpComponent.lmp,
          IsoNewEngland.bucket5x16, Date(2017, 1, 1), Date(2017, 1, 5));
      expect(data.length, 3);
      expect(data.toList(), [
        IntervalTuple(Date(2017, 1, 3, location: location), 45.64124999999999),
        IntervalTuple(Date(2017, 1, 4, location: location), 39.103125),
        IntervalTuple(Date(2017, 1, 5, location: location), 56.458749999999995)
      ]);
    });

    test('get monthly peak price between two dates', () async {
      var data = await api.getMonthlyLmpBucket(4000, LmpComponent.lmp,
          IsoNewEngland.bucket5x16, Month(2017, 1), Month(2017, 8));
      expect(data.length, 8);
      expect(data.first,
          IntervalTuple(Month(2017, 1, location: location), 42.55883928571426));
    });

    test('get hourly price for 2017-01-01', () async {
      var data = await api.getHourlyLmp(
          4000, LmpComponent.lmp, Date(2017, 1, 1), Date(2017, 1, 1));
      expect(data.length, 24);
      expect(
          data.first,
          IntervalTuple(
              Hour.beginning(TZDateTime(location, 2017, 1, 1)), 35.12));
    });

    test('get daily prices all nodes', () async {
      var data = await api.getDailyPricesAllNodes(LmpComponent.lmp,
          Date(2017, 1, 1), Date(2017, 1, 3));
      expect(data.length, 1136);
      var p321 = data[321];
      expect(p321.first.value, 37.755);
    });

  });
}

speedTest(String rootUrl) async {
  var location = getLocation('US/Eastern');
  var client = Client();
  var api = DaLmp(client, rootUrl: rootUrl);

  var data = await api.getHourlyLmp(
      4000, LmpComponent.lmp, Date(2018, 1, 1), Date(2019, 1, 1));
  var days = data.intervals.map((ival) => Date.fromTZDateTime(ival.start))
      .toSet();
  var allDays = Interval(TZDateTime(location, 2018), TZDateTime(location, 2019))
      .splitLeft((dt) => Date.fromTZDateTime(dt)).toSet();
  print(allDays.difference(days));

  var sw = Stopwatch()..start();
  for (int i=0; i<10; i++) {
    var mTs = toMonthly(data, mean);
  }
  sw.stop();
  print('Milliseconds: ${sw.elapsedMilliseconds}');
}


main() async {
  await initializeTimeZone();

  String rootUrl = "http://localhost:8080/"; // testing
  await tests(rootUrl);


}

