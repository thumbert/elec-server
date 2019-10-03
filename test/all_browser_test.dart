@TestOn('chrome')

///  pub run test -p "chrome" test/all_browser_test.dart

import 'dart:math';
import 'package:test/test.dart';
import 'package:timezone/browser.dart';
import 'package:date/date.dart';
import 'package:http/browser_client.dart';
import 'package:timeseries/timeseries.dart';
import 'package:dama/dama.dart';
import 'package:elec/src/common_enums.dart';
import 'package:elec_server/client/isoexpress/dalmp.dart';


tests(String rootUrl) async {
  test('Add 2 numbers', () {
    expect(1+2, 3);
  });
//  test('LMP speed tests', () async {
//    var location = getLocation('US/Eastern');
//    var client = BrowserClient();
//    var api = DaLmp(client, rootUrl: rootUrl);
//    var data = await api.getHourlyLmp(
//        4000, LmpComponent.lmp, Date(2018, 1, 1), Date(2019, 1, 1));
//    expect(location.name, 'US/Eastern');
//    var sw = Stopwatch()..start();
//    for (int i=0; i<10; i++) {
//      var mTs = toMonthly(data, mean);
//    }
//    sw.stop();
//    print('Milliseconds: ${sw.elapsedMilliseconds}');
//  });
  test('speed test 1', () {
    var n = 10000;
    var rand = Random(0);
    var x = List.generate(n, (i) => rand.nextDouble());

    var res = <num>[];
    var sw = Stopwatch()..start();
    for (int i=0; i<1000; i++) {
      for (int j=0; j<n; j++) {
        x[j] += i;
      }
      res.add(x.reduce((a, b) => a + b));
    }
    sw.stop();
    print('Milliseconds: ${sw.elapsedMilliseconds}');
  });



}


void main() async {
  await initializeTimeZone();

  var rootUrl = "http://localhost:8080/"; // testing
  await tests(rootUrl);
}