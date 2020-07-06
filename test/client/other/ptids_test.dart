library test.client.other.ptids_test;

import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/client/other/ptids.dart';

void tests() async {
  var api = PtidsApi(Client());
  group('API ptid table:', () {
    test('get current ptid table', () async {
      var data = await api.getPtidTable();
      expect(data.length > 950, true);
      expect(data.first['ptid'], 4000);
      var me = data.firstWhere((e) => e['ptid'] == 4001);
      expect(me, {'ptid': 4001, 'name': '.Z.MAINE', 'spokenName': 'MAINE',
        'type': 'zone'});
    });

  });
}

void main() async {
  await initializeTimeZone();
  await tests();
}
