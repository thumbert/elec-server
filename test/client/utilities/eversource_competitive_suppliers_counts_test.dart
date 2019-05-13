library test.client.utilities.eversource_load_test;


import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/client/utilities/eversource/eversource_competitive_suppliers.dart';

tests() async {
  var api = EversourceCompetitiveSuppliers(Client());
  var location = getLocation('US/Eastern');
  group('Eveversource competitive suppliers test:', () {
    test('get suppliers for CT (CL&P)', () async {
      var start = Date(2014, 1, 1, location: location);
      var end = Date(2014, 12, 31, location: location);
      var data = await api.getCustomerCounts(start, end);
      expect(data.length == 8760, true);
//      var first = data.first;
//      expect(first.value is Map<String,num>, true);
//      expect(first.value['LRS'], 86.304);
//      expect(first.value.keys.toList(), ['LRS', 'L-CI', 'RES', 'S-CI',
//        'S-LT', 'SS Total', 'Competitive Supply']);
    });
  });
}

main() async {
  await initializeTimeZone();
  await tests();
}
