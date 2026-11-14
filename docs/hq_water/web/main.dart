import 'package:date/date.dart';
import 'package:elec_server/client/hq/fuel_mix.dart';
import 'package:hq_water/fuel_mix.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart' show getLocation;
import 'package:web/web.dart' as web;

void main() async {
  const rootUrl = String.fromEnvironment('RUST_SERVER');
  print('Root URL: $rootUrl');
  initializeTimeZones(); 
  final tz = getLocation('America/New_York');

  var ts = await getHydroGeneration(
    term: Term.parse('Jan23-Dec35', tz),
    rootUrl: rootUrl,
  );

  makeMonthlySeasonalChart(
    web.document.querySelector('#chart1') as web.HTMLDivElement,
    ts,
  );
  makeHourlyChart(
    web.document.querySelector('#chart2') as web.HTMLDivElement,
    ts,
  );


  final now = DateTime.now();
  final element = web.document.querySelector('#output') as web.HTMLDivElement;
  element.textContent =
      'The time is ${now.hour}:${now.minute} '
      'and your Dart web app is running!';
}
