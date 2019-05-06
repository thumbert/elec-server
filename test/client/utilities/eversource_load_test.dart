library test.client.utilities.eversource_load_test;


import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/client/utilities/eversource/eversource_load.dart';

tests() async {
  var api = EversourceLoad(Client());
  var location = getLocation('US/Eastern');
  group('API ptid table:', () {
    test('get current ptid table', () async {
      var start = Date(2014, 1, 1, location: location);
      var end = Date(2014, 12, 31, location: location);
      var data = await api.getCtLoad(start, end);
      expect(data.length == 8760, true);
//      expect(data.first['ptid'], 4000);
//      var me = data.firstWhere((e) => e['ptid'] == 4001);
//      expect(me, {'ptid': 4001, 'name': '.Z.MAINE', 'spokenName': 'MAINE',
//        'type': 'zone'});
    });

  });
}

main() async {
  await initializeTimeZone();
  await tests();
}
