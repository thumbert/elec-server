library test.db.weather.noaa_daily_summary_test;

import 'dart:io';

import 'package:elec_server/api/weather/api_noaa_daily_summary.dart';
import 'package:elec_server/client/weather/noaa_daily_summary.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/src/db/weather/noaa_daily_summary.dart';
import 'package:timezone/timezone.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
void tests(String rootUrl) async {
  var archive = NoaaDailySummaryArchive()
    ..dir = (Platform.environment['HOME'] ?? '') +
        '/Downloads/Archive/Weather/Noaa/DailySummary/Raw/';
  group('NOAA daily summary db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read file for Boston', () async {
      var file = archive.getFilename('USW00014739');
      var data = archive.processFile(file);
      expect(data.length > 50, true);
      expect(data.first.keys.toSet(), {
        'stationId',
        'year',
        'tMin',
        'tMax',
      });
      var x0 = data.firstWhere((e) => e['year'] == 1970);
      expect((x0['tMin'] as List).take(3).toList(), [16, 19, 17]);
      expect((x0['tMax'] as List).take(3).toList(), [29, 28, 30]);
    });
  });
  group('NOAA daily summary API tests:', () {
    var api = ApiNoaaDailySummary(archive.db);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('Get ', () async {
      var res =
          await api.apiGetStationId('USW00014739', '2019-01-15', '2019-02-28');
      expect(res.length, 45);
      expect(res.first, {
        'date': '2019-01-15',
        'tMin': 24,
        'tMax': 39,
      });
      expect(res.last, {
        'date': '2019-02-28',
        'tMin': 19,
        'tMax': 31,
      });
    });
  });
  group('Monthly asset ncpc client tests:', () {
    var client = NoaaDailySummary(http.Client(), rootUrl: rootUrl);
    test('get min/max temperatures', () async {
      var term = Term.parse('15Jan19-28Feb19', UTC);
      var data = await client.getDailyHistoricalMinMaxTemperature(
          'BOS', term.interval);
      expect(data.length, 45);
      var first = data.first;
      expect(first.interval, Date.utc(2019, 1, 15));
      expect(first.value, {'min': 24, 'max': 39});
    });
    test('get average temperature', () async {
      var term = Term.parse('15Jan19-28Feb19', UTC);
      var data =
          await client.getDailyHistoricalTemperature('BOS', term.interval);
      expect(data.length, 45);
      var first = data.first;
      expect(first, IntervalTuple<num>(Date.utc(2019, 1, 15), 31.5));
    });
  });
}

void main() async {
  initializeTimeZones();
  DbProd();
  // await NoaaDailySummaryArchive().setupDb();

  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
