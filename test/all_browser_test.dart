@TestOn('chrome')
import 'dart:math';
import 'package:test/test.dart';
import 'package:timezone/browser.dart';

///  pub run test -p "chrome" test/all_browser_test.dart
void tests(String rootUrl) async {
  test('Add 2 numbers', () {
    expect(1 + 2, 3);
  });
//  test('LMP speed tests', () async {
//    var location = getLocation('America/New_York');
//    var client = BrowserClient();
//    var api = DaLmp(client, rootUrl: rootUrl);
//    var data = await api.getHourlyLmp(
//        4000, LmpComponent.lmp, Date(2018, 1, 1), Date(2019, 1, 1));
//    expect(location.name, 'America/New_York');
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
    for (int i = 0; i < 1000; i++) {
      for (int j = 0; j < n; j++) {
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

  var rootUrl = "http://localhost:8080"; // testing
  tests(rootUrl);
}
