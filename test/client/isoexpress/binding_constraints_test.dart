library test.client.binding_constraints_test;

import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/isoexpress/binding_constraints.dart';

void tests() async {
  var location = getLocation('America/New_York');
  var api = BindingConstraintsApi(Client());
  group('API binding constraints:', () {
    test('get da binding constraints data for 2 days', () async {
      var interval = Interval(TZDateTime(location, 2017, 1, 1),
          TZDateTime(location, 2017, 1, 3));
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
    test('get all occurences of constraint SHFHGE', () async {
      var aux = await api.getDaBindingConstraint('SHFHGE', Date(2017, 1, 1),
        Date(2017, 2, 1));
      expect(aux.length, 413);
    });

  });
}

void main() async {
  await initializeTimeZone();
  await tests();
}
