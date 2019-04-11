library test.client.isoexpress.system_demand;

import 'package:elec/risk_system.dart';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/client/isoexpress/system_demand.dart';

tests(String rootUrl) async {
  group('DAM prices client tests: ', () {
    var location = getLocation('US/Eastern');
    var client = Client();
    var api = SystemDemand(client, rootUrl: rootUrl);

    test('get daily peak price between two dates', () async {
      var data = await api.getSystemDemand(Market.rt, Date(2017, 1, 1), Date(2017, 1, 5));
      expect(data.length, 120);
      expect(data.take(3).toList(), [
        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 0)), 12268.9),
        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 1)), 11823.69),
        IntervalTuple(Hour.containing(TZDateTime(location, 2017, 1, 1, 2)), 11790.9),
      ]);
    });

  });
}

main() async {
  await initializeTimeZone();

  String rootUrl = "http://localhost:8080/"; // testing
  await tests(rootUrl);
}

