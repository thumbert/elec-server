import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/client/weather/noaa_daily_summary.dart';
import 'package:elec_server/client/weather/normal_temperature.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/db/weather/normal_temperature.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  group('Normal temperature client tests', () {
    var nt = NormalTemperature(Client());
    test('get one airport', () async {
      var bos = await nt.getNormalTemperature('BOS');
      expect(bos.length, 366);
      expect(bos.first < 40, true);
    });
  });
}

Future<void> analysis() async {
  final airport = 'BOS';
  var client = NoaaDailySummary(Client(), rootUrl: dotenv.env['ROOT_URL']!);
  var term = Term.parse('1Jan1970-29Feb24', UTC);
  var data =
      await client.getDailyHistoricalMinMaxTemperature(airport, term.interval);
  final ts = TimeSeries.fromIterable(data.map((e) =>
      IntervalTuple(e.interval, (min: e.value['min']!, max: e.value['max']!))));
  final dir = Directory(
      '${Platform.environment['HOME']}/Documents/repos/git/thumbert/rascal/'
      'presentations/energy/temperature/$airport/src/assets');
  final wn = NormalTemperatureAnalysis(ts, dir: dir);
  wn.makeReport(airport);

  /// Write the results in the archive folder
  var jsonFile = File('${getNormalTemperatureArchive().dir}/$airport.json');
  jsonFile.writeAsStringSync(json.encode({
    'airportCode': airport,
    'asOfDate': ts.last.interval.toString(),
    'normalTemperature': wn
        .normalTemperature()
        .map((e) => num.parse(e.toStringAsFixed(1)))
        .toList(),
  }));
  print('Wrote file ${jsonFile.path}');
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  // await analysis();
  tests(dotenv.env['ROOT_URL']!);
}
