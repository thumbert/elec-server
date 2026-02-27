import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/battery.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/shape.dart';
import 'package:elec_server/client/lmp.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';

Future<void> historicalTb4(TimeSeries<num> lmp) async {
  var byDay = groupBy(lmp, (e) => Date.containing(e.interval.start));
  var result = TimeSeries<num>();
  for (var day in byDay.keys) {
    var dayLmp = TimeSeries.fromIterable(byDay[day]!);
    var it = tbN(dayLmp, n: 4);
    it.value = it.value * 4;
    result.add(it);
  }

  var tb4 = result.toMonthly(sum);
  var hours = tb4
      .map((e) => IntervalTuple(e.interval, Bucket.atc.countHours(e.interval)))
      .toTimeSeries();
  var out = tb4 / hours;
  print(out);
}

Future<void> historicalContinuousValuation(TimeSeries<num> lmp) async {
  var aux = minMaxDailyPriceForBlock(lmp, 4);
  var ts = TimeSeries.fromIterable(aux.map((e) =>
      IntervalTuple(e.interval, 4 * (e.value.maxPrice - e.value.minPrice))));

  var mTs = ts.toMonthly(sum);
  var hours = mTs
      .map((e) => IntervalTuple(e.interval, Bucket.atc.countHours(e.interval)))
      .toTimeSeries();
  var out = mTs / hours;
  print(out);

  print(out.toYearly(mean));
}

Future<TimeSeries<num>> getLmp({Term? term}) async {
  term = term ?? Term.parse('Jan21-Feb26', IsoNewEngland.location);
  var lmp = await getHourlyLmpIsone(
      market: Market.da,
      ptid: 4000,
      component: LmpComponent.lmp,
      term: term,
      rustServer: dotenv.env['RUST_SERVER']!);
  return lmp;
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  var lmp = await getLmp();
  // await historicalTb4(lmp);
  await historicalContinuousValuation(lmp);
}
