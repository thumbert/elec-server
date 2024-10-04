library db.isoexpress.rt_lmp_5min;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart';
import '../lib_iso_express.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class RtLmp5MinArchive {
  RtLmp5MinArchive({required this.dir});

  static final log = Logger('ISONE RT LMP');
  final String dir;
  final String reportName = 'Real-Time Energy Market 5Min LMP Report';

  /// /fiveminutelmp/day/{day}/location/{locationId}
  /// /fiveminutelmp/{Type}/day/{day}/location/{locationId}
  /// Report type: 'final' or 'prelim'
  /// --->  You can also get all locations by start hour, e.g.
  /// 'https://webservices.iso-ne.com/api/v1.1/fiveminutelmp/rt/final/day/${yyyymmdd(asOfDate)}/starthour/${starthour}';
  String getUrl(
          {required Date asOfDate, required String type, required int ptid}) =>
      'https://webservices.iso-ne.com/api/v1.1/fiveminutelmp/$type/day/${yyyymmdd(asOfDate)}/location/$ptid';

  File getFilename(Date asOfDate,
      {required String type, required int ptid, String extension = 'json'}) {
    if (extension == 'json') {
      return File(
          '$dir/Raw/lmp5min_rt_${type}_${ptid}_${yyyymmdd(asOfDate)}.json');
    } else {
      throw StateError('Unsupported extension $extension');
    }
  }

  /// Return a Map with elements like this
  /// ```dart
  /// {
  ///   'ptid': 4000,
  ///   'report': 'final',
  ///   'date': '2022-12-22',
  ///   'minuteOfDay': 130,
  ///   'lmp': <num>,
  ///   'mcc': <num>,
  ///   'mlc': <num>,
  /// }
  /// ```
  List<Map<String, dynamic>> processFile(File file) {
    if (file.path.endsWith('json') && file.existsSync()) {
      return _processFileJson(file);
    } else {
      throw ArgumentError('File $file does not exist!');
    }
  }

  List<Map<String, dynamic>> _processFileJson(File file) {
    var aux = json.decode(file.readAsStringSync()) as Map;
    late List<Map<String, dynamic>> xs;
    if (aux.containsKey('FiveMinLmps')) {
      if (aux['FiveMinLmp'] == '') return <Map<String, dynamic>>[];
      xs = (aux['FiveMinLmps']['FiveMinLmp'] as List)
          .cast<Map<String, dynamic>>();
    } else {
      throw ArgumentError('Can\'t find key HourlyLmps in file $file');
    }
    var name = basename(file.path);
    var fragments = name.split('_');
    final report = fragments[2];
    final ptid = int.parse(fragments[3]);
    var res = xs.map((e) {
      var dt = TZDateTime.parse(IsoNewEngland.location, e['BeginDate']);
      var dt0 = TZDateTime(IsoNewEngland.location, dt.year, dt.month, dt.day);
      return {
        'ptid': ptid,
        'report': report,
        'date': (e['BeginDate'] as String).substring(0, 10),
        'minuteOfDay':
            (dt.millisecondsSinceEpoch - dt0.millisecondsSinceEpoch) ~/ 60000,
        'lmp': e['LmpTotal'] as num,
        'mcc': e['CongestionComponent'] as num,
        'mlc': e['LossComponent'] as num,
      };
    }).toList();

    return res;
  }

  Future downloadDay(Date day,
      {required String type, required int ptid}) async {
    var user = dotenv.env['ISONE_WS_USER']!;
    var pwd = dotenv.env['ISONE_WS_PASSWORD']!;

    var client = HttpClient()
      ..addCredentials(Uri.parse(getUrl(asOfDate: day, type: type, ptid: ptid)),
          '', HttpClientBasicCredentials(user, pwd))
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var url = getUrl(asOfDate: day, type: type, ptid: ptid);
    var request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    await response.pipe(getFilename(day, type: type, ptid: ptid).openWrite());
  }

  /// Aggregate a list of days into a csv.gz file.  Each row of the file
  /// looks like:
  ///
  /// ```dart
  /// {
  ///   'ptid': 4000,
  ///   'report': 'final',
  ///   'date': '2022-12-22',
  ///   'minuteOfDay': 125,
  ///   'lmp': <num>,
  ///   'mcc': <num>,
  ///   'mlc: <num>,
  /// }
  /// ```
  List<Map<String, dynamic>> aggregateDays(List<Date> days,
      {required String type, required int ptid}) {
    assert(days.first.location == IsoNewEngland.location);
    var out = <Map<String, dynamic>>[];
    for (var date in days) {
      log.info('...  Working on $date, $ptid, type: $type');
      final file = getFilename(date, type: type, ptid: ptid, extension: 'json');
      if (file.existsSync()) {
        var rows = processFile(file);
        out.addAll(rows);
      } else {
        throw StateError('Missing file for $date');
      }
    }
    log.info('aggregated data has ${out.length} rows!');
    return out;
  }

  int makeGzFileForMonth(Month month,
      {required String type, required int ptid}) {
    var days = month.days();
    final xs = aggregateDays(days, type: type, ptid: ptid);
    final file = File(
        '$dir/month/$ptid/rt_lmp5min_${type}_${month.toIso8601String()}.csv');
    var converter = const ListToCsvConverter();
    var sb = StringBuffer();
    sb.writeln(converter.convert([xs.first.keys.toList()]));
    for (var offer in xs) {
      sb.writeln(converter.convert([offer.values.toList()]));
    }
    file.writeAsStringSync(sb.toString());

    // gzip it!
    var res = Process.runSync('gzip', ['-f', file.path], workingDirectory: dir);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(file.path)} has failed');
    }
    log.info('Gzipped file ${basename(file.path)}');

    return 0;
  }

  /// Create the Db from scratch
  int updateDuckDb({
    required int ptid,
    required String reportType,
    required String pathDbFile,
    required List<Month> months,
  }) {
    final con = Connection(pathDbFile);
    con.execute('''
CREATE TABLE IF NOT EXISTS rt_lmp5min (
    ptid UINTEGER NOT NULL,
    report VARCHAR(6) NOT NULL,
    date DATE NOT NULL,
    minuteOfDay UINTEGER NOT NULL,
    lmp DECIMAL(9,4) NOT NULL,
    mcc DECIMAL(9,4) NOT NULL,
    mcl DECIMAL(9,4) NOT NULL,
);
''');
    for (var month in months) {
      con.execute('''
DELETE FROM rt_lmp5min 
WHERE ptid = $ptid
AND report = '$reportType'
AND date >= '${month.startDate}'
AND date < '${month.next.startDate}';
      ''');
      con.execute('''
INSERT INTO rt_lmp5min
FROM read_csv(
    '$dir/month/$ptid/rt_lmp5min_${reportType}_${month.toIso8601String()}.csv.gz', 
    header = true, 
    columns = {
      'ptid': 'UINTEGER',
      'report': 'VARCHAR(6)',
      'date': 'DATE',
      'minuteOfDay': 'UINTEGER',
      'lmp': 'DECIMAL(9,4)', 
      'mcc': 'DECIMAL(9,4)', 
      'mcl': 'DECIMAL(9,4)', 
    },
    dateformat = '%Y-%m-%d');
''');
    }
    con.close();
    return 0;
  }
}
