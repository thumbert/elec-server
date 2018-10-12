library test.client.da_energy_offer_test;

import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/client/isoexpress/binding_constraints.dart';

tests() async {
  Location location = getLocation('US/Eastern');
  var api = BindingConstraintsApi(new Client());
  group('API binding constraints:', () {
    test('get da binding constraints data for 2 days', () async {
      var interval = Interval(new TZDateTime(location, 2017, 1, 1),
          new TZDateTime(location, 2017, 1, 3));
      var aux = await api.getDaBindingConstraints(interval);
      expect(aux.length, 44);
      var first = aux.first;
      expect(first, {
        'Constraint Name': 'SHFHGE',
        'Contingency Name': 'Interface',
        'Interface Flag': 'Y',
        'Marginal Value': -7.31,
        'hourBeginning': '2017-01-01 00:00:00.000-0500',
      });
    });
    test('get da binding constraints data for 2 days', () async {
      var aux = await api.getDaBindingConstraint('PARIS   O154          A LN');
      expect(aux.length > 100, true);
    });

  });
}

main() async {
  await initializeTimeZone();
  await tests();
}
