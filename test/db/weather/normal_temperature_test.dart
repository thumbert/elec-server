library test.weather.dual_strike_option_test;

import 'dart:io';

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/weather/noaa_daily_summary.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:elec/src/weather/normal_temperature.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

// void tests() {
//   group('Normal temperature tests', () {
//     var data = [
//       {'temperature': 35, 'price': 89},
//       {'temperature': 31, 'price': 160},
//       {'temperature': 30, 'price': 168},
//       {'temperature': 22, 'price': 160},
//     ];
//     var ds1 = DualStrikeOption(cold2Payoff(32, 150), maxPayout: 50);
//     test('one option', () {
//       var payoffs = data.map((Map e) => ds1.value(e['temperature'], e['price']));
//       expect(payoffs.take(4).toList(), [0, 10, 36, 50]);
//     });
//   });
// }

Future<void> analysis() async {
  var client = NoaaDailySummary(Client(), rootUrl: dotenv.env['ROOT_URL']!);
  var term = Term.parse('1Jan1970-29Feb24', UTC);
  var data =
      await client.getDailyHistoricalMinMaxTemperature('BOS', term.interval);
  final ts = TimeSeries.fromIterable(data.map((e) =>
      IntervalTuple(e.interval, (min: e.value['min']!, max: e.value['max']!))));
  print(ts.take(3));


  final dir = Directory('${Platform.environment['HOME']}/Documents/repos/git/thumbert/rascal/'
    'presentations/energy/temperature/bos/src/assets');
  final wn = NormalTemperatureAnalysis(ts, dir: dir);
  wn.makeReport();


}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await analysis();
  // tests();
}
