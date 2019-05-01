library test.client.isoexpress.system_demand;

import 'package:elec/risk_system.dart';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/client/isoexpress/system_demand.dart';

tests(String rootUrl) async {
  group('System demand client tests: ', () {
    var location = getLocation('US/Eastern');
    var client = Client();
    var api = SystemDemand(client, rootUrl: rootUrl);

    test('get system demand between two dates', () async {
      var data = await api.getSystemDemand(Market.rt, Date(2017, 1, 1), Date(2017, 1, 5));
      expect(data.length, 120);
      expect(data.take(3).toList(), [
        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 0)), 12268.9),
        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 1)), 11823.69),
        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 2)), 11790.9),
      ]);
    });
    test('get system demand for 1 year', () async {
      var year = 2016;
      var data = await api.getSystemDemand(Market.rt, Date(year, 1, 1), Date(year, 12, 31));

      var grp = data.splitByIndex((e) => Date.fromTZDateTime(e.start));
      var aux = grp.entries.map((e) => MapEntry(e.key,e.value.length));
      var days = Interval(TZDateTime(location, year), TZDateTime(location, year+1))
        .splitLeft((dt) => Date.fromTZDateTime(dt)).toSet();
      var missingDays = days.difference(aux.map((e) => e.key).toSet());
      if (missingDays.length != 0) {
        print("missing days for rt system demand");
        print(missingDays);
      }
      expect(missingDays.length, 0);

//      var count = Map.fromEntries(aux.where((e) => e.value != 24));
//      expect(count.length, 2);
//      expect(count[Date(2017, 3, 12, location: location)], 23);
//      expect(count[Date(2017, 11, 5, location: location)], 25);
//      expect(data.length, 8760);
//      expect(data.take(3).toList(), [
//        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 0)), 12268.9),
//        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 1)), 11823.69),
//        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 2)), 11790.9),
//      ]);
    });

  });
}

main() async {
  await initializeTimeZone();

  var rootUrl = "http://localhost:8080/"; // testing
  await tests(rootUrl);
}

