library db.isoexpress.rt_reserve_prices;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/src/utils/string_extensions.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:table/table.dart';

class RtReservePriceArchive {
  RtReservePriceArchive({required this.dir});

  final String dir;
  static final log = Logger('5min RT reserve prices and designations');

  File getFilename(Date asOfDate) {
    return File("$dir/Raw/5min_rt_reserve_prices_$asOfDate.json");
  }

  String getUrl(Date asOfDate) =>
      "https://webservices.iso-ne.com/api/v1.1/fiveminutereserveprice/final/day/${yyyymmdd(asOfDate)}";

  /// ISO has not published data for these days
  static final missingDays = <Date>{
    // Date(2023, 9, 17, location: IsoNewEngland.location),
  };

  /// Read the file for one day.
  ///
  ///
  List<Map<String, dynamic>> processFile(File file) {
    if (extension(file.path) != '.json') {
      throw ArgumentError('File needs to be a json file');
    }
    var str = file.readAsStringSync();
    var aux = json.decode(str);
    var xs = aux['FiveMinReservePrices']!['FiveMinReservePrice'] as List;

    // Pivot the data so all variables are in columns.
    // First, split the entires by timestamp, reserve zone id
    final nest = Nest()
      ..key((e) => e['BeginDate'])
      ..key((e) => e['ReserveZoneId'])
      ..rollup((List es) => es.first);
    var ys = nest.map(xs);

    var res = <Map<String, dynamic>>[];
    // Do the pivot, append the zone id to the variable name
    for (var timeStamp in ys.keys) {
      var data = ys[timeStamp]! as Map;
      var one = {
        'IntervalBeginning5Min': timeStamp,
      };
      for (var zoneId in data.keys) {
        var zoneData = data[zoneId]! as Map<String, dynamic>;
        final name =
            (zoneData['ReserveZoneName'] as String).toLowerCase().capitalize();
        zoneData.remove('BeginDate');
        zoneData.remove('ReserveZoneId');
        zoneData.remove('ReserveZoneName');
        one.addEntries(
            zoneData.entries.map((e) => MapEntry('$name${e.key}', e.value)));
      }
      res.add(one);
    }

    return res;
  }

  /// File is in the long format, ready for duckdb to upload
  ///
  int makeGzFileForMonth(Month month) {
    assert(month.location == IsoNewEngland.location);
    var today = Date.today(location: IsoNewEngland.location);
    var days = month.days();
    var xs = <Map<String, dynamic>>[];
    for (var day in days) {
      print('   Processing day $day...');
      if (day.isAfter(today)) continue;
      if (missingDays.contains(day)) continue;
      var file = getFilename(day);
      xs.addAll(processFile(file));
    }

    final converter = ListToCsvConverter();
    var sb = StringBuffer();
    var names = xs.first.keys.toList();
    names = names.map((e) => e.replaceAll('TenMin', '10Min')).toList();
    sb.writeln(converter.convert([names]));
    for (var x in xs) {
      sb.writeln(converter.convert([x.values.toList()]));
    }
    final file =
        File('$dir/month/rt_reserve_price_${month.toIso8601String()}.csv');
    file.writeAsStringSync(sb.toString());

    // gzip it!
    var res = Process.runSync('gzip', ['-f', file.path], workingDirectory: dir);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(file.path)} has failed');
    }
    log.info('Gzipped file ${basename(file.path)}');

    return 0;
  }

  int testDuckDb() {
    final con = Connection("/home/adrian/Downloads/Archive/IsoExpress/PricingReports/RtReservePrice/bar.duckdb");
    con.execute(r'''
CREATE TABLE IF NOT EXISTS bar (
    IntervalBeginning5Min TIMESTAMPTZ,
    Ros10MinSpinRequirement FLOAT,
    RosTotal10MinRequirement FLOAT,
    RosTotal30MinRequirement FLOAT,
    RosTmsrDesignatedMw FLOAT,
    RosTmnsrDesignatedMw FLOAT,
    RosTmorDesignatedMw FLOAT,
    RosTmsrClearingPrice FLOAT,
    RosTmnsrClearingPrice FLOAT,
    RosTmorClearingPrice FLOAT,
    SwctTotal30MinRequirement FLOAT,
    SwctTmsrDesignatedMw FLOAT,
    SwctTmnsrDesignatedMw FLOAT,
    SwctTmorDesignatedMw FLOAT,
    SwctTmsrClearingPrice FLOAT,
    SwctTmnsrClearingPrice FLOAT,
    SwctTmorClearingPrice FLOAT,
    CtTotal30MinRequirement FLOAT,
    CtTmsrDesignatedMw FLOAT,
    CtTmnsrDesignatedMw FLOAT,
    CtTmorDesignatedMw FLOAT,
    CtTmsrClearingPrice FLOAT,
    CtTmnsrClearingPrice FLOAT,
    CtTmorClearingPrice FLOAT,
    NemabstnTotal30MinRequirement FLOAT,
    NemabstnTmsrDesignatedMw FLOAT,
    NemabstnTmnsrDesignatedMw FLOAT,
    NemabstnTmorDesignatedMw FLOAT,
    NemabstnTmsrClearingPrice FLOAT,
    NemabstnTmnsrClearingPrice FLOAT,
    NemabstnTmorClearingPrice FLOAT
);
INSERT INTO bar
FROM read_csv(
    '/home/adrian/Downloads/Archive/IsoExpress/PricingReports/RtReservePrice/month/rt_reserve_price_2021-01.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
    ''');
    con.close();
    return 0;
  }

  //
  int updateDuckDb({required List<Month> months, required String pathDbFile}) {
    final con = Connection(pathDbFile);
    con.execute(r'''
CREATE TABLE IF NOT EXISTS rt_reserve_price (
    IntervalBeginning5Min TIMESTAMPTZ,
    Ros10MinSpinRequirement FLOAT,
    RosTotal10MinRequirement FLOAT,
    RosTotal30MinRequirement FLOAT,
    RosTmsrDesignatedMw FLOAT,
    RosTmnsrDesignatedMw FLOAT,
    RosTmorDesignatedMw FLOAT,
    RosTmsrClearingPrice FLOAT,
    RosTmnsrClearingPrice FLOAT,
    RosTmorClearingPrice FLOAT,
    SwctTotal30MinRequirement FLOAT,
    SwctTmsrDesignatedMw FLOAT,
    SwctTmnsrDesignatedMw FLOAT,
    SwctTmorDesignatedMw FLOAT,
    SwctTmsrClearingPrice FLOAT,
    SwctTmnsrClearingPrice FLOAT,
    SwctTmorClearingPrice FLOAT,
    CtTotal30MinRequirement FLOAT,
    CtTmsrDesignatedMw FLOAT,
    CtTmnsrDesignatedMw FLOAT,
    CtTmorDesignatedMw FLOAT,
    CtTmsrClearingPrice FLOAT,
    CtTmnsrClearingPrice FLOAT,
    CtTmorClearingPrice FLOAT,
    NemabstnTotal30MinRequirement FLOAT,
    NemabstnTmsrDesignatedMw FLOAT,
    NemabstnTmnsrDesignatedMw FLOAT,
    NemabstnTmorDesignatedMw FLOAT,
    NemabstnTmsrClearingPrice FLOAT,
    NemabstnTmnsrClearingPrice FLOAT,
    NemabstnTmorClearingPrice FLOAT
);
''');
    for (var month in months) {
      // remove the data if it's already there
//       con.execute('''
// DELETE FROM rt_reserve_price 
// WHERE "IntervalBeginning5Min" >= '${month.start.toIso8601String()}'
// AND "IntervalBeginning5Min" < '${month.next.start.toIso8601String()}';
//       ''');
      // reinsert the data
      con.execute('''
INSERT INTO rt_reserve_price
FROM read_csv(
    '$dir/month/rt_reserve_price_${month.toIso8601String()}.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
''');
      log.info('   Inserted month ${month.toIso8601String()} into DuckDb');
    }
    con.close();
    return 0;
  }
}
