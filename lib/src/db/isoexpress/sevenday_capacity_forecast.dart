library db.isoexpress.sevenday_capacity_forecast;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/isoexpress/sevenday_capacity_forecast.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

class SevenDayCapacityForecastArchive {
  SevenDayCapacityForecastArchive({required this.dir});

  final String dir;
  static final log = Logger('7Day Capacity forecast');

  File getFilename(Date asOfDate) {
    return File("$dir/Raw/7dayforecast_$asOfDate.json");
  }

  String getUrl(Date asOfDate) =>
      "https://webservices.iso-ne.com/api/v1.1/sevendayforecast/day/${yyyymmdd(asOfDate)}/all";

  /// ISO has not published data for these days
  static final missingDays = {
    Date(2023, 9, 17, location: IsoNewEngland.location),
  };

  List<DailyForecast> processFile(File file) {
    if (extension(file.path) != '.json') {
      throw ArgumentError('File needs to be a json file');
    }
    var out = <DailyForecast>[];
    var str = file.readAsStringSync();
    var aux = json.decode(str);
    var xs = (aux['SevenDayForecasts']!['SevenDayForecast'] as List).first
        as Map<String, dynamic>;
    if (xs case {'MarketDay': List forecasts}) {
      for (Map<String, dynamic> x in forecasts) {
        out.add(DailyForecast.fromJson(x));
      }
    }
    return out;
  }

  /// File is in the long format, ready for duckdb to upload
  ///
  int makeGzFileForMonth(Month month) {
    assert(month.location == IsoNewEngland.location);
    var today = Date.today(location: IsoNewEngland.location);
    var days = month.days();
    var xs = <DailyForecast>[];
    for (var day in days) {
      // file is published at 9AM every day
      if (day.isAfter(today)) continue;
      if (missingDays.contains(day)) continue;
      var file = getFilename(day);
      xs.addAll(processFile(file));
    }

    final converter = ListToCsvConverter();    
    var sb = StringBuffer();
    sb.writeln(DailyForecast.names.join(','));
    for (var x in xs) {
      sb.writeln(converter.convert([x.toList()]));
    }
    final file =
        File('$dir/month/7day_capacity_forecast_${month.toIso8601String()}.csv');
    file.writeAsStringSync(sb.toString());

    // gzip it!
    var res = Process.runSync('gzip', ['-f', file.path], workingDirectory: dir);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(file.path)} has failed');
    }
    log.info('Gzipped file ${basename(file.path)}');

    return 0;
  }
}
