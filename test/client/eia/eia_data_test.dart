library test.isone_dalmp_test;

import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/eia/eia_data.dart';

/// retrieve the key from the environment variables
String? getEiaKey() {
  var env = Platform.environment;
  if (!env.containsKey('EIA_API_KEY')) {
    throw StateError('EIA_API_KEY is not set as an enviroment variable.');
  }
  return env['EIA_API_KEY'];
}


tests() async {
  var key = getEiaKey();
  var api = EiaApi(Client(), key);
  group('EIA client tests:', () {
    test('get weekly working gas in underground storage', () async {
      var aux = await api.getSeries('NG.NW2_EPG0_SWO_R48_BCF.W');
      expect(aux['f'], 'W');
      expect(aux['units'], 'Billion Cubic Feet');
      expect(aux.containsKey('data'), true);
      expect((aux['data'] as List).length > 400, true);
      var ts = processSeries(aux);
      expect(ts.observationAt(Date.utc(2018,12,21)).value, 2725);
      //ts.sublist(460).forEach(print);
    });
  });
}

main() async {
  await initializeTimeZone();
  await tests();
}
