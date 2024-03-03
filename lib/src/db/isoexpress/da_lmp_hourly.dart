library db.isoexpress.da_lmp_hourly;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class DaLmpHourlyArchive extends DailyIsoExpressReport {
  DaLmpHourlyArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'isoexpress',
        collectionName: 'da_lmp_hourly');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}PricingReports/DaLmpHourly/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Energy Market Hourly LMP Report';
  }

  // @override
  // String getUrl(Date? asOfDate) =>
  //     'https://www.iso-ne.com/static-transform/csv/histRpts/da-lmp/WW_DALMP_ISO_${yyyymmdd(asOfDate)}.csv';

  @override
  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/hourlylmp/da/final/day/${yyyymmdd(asOfDate)}';

  /// I encoded the json file using msgpack and got only a marginal improvement
  /// to file size.  File size went down from 6.2 MB to 5.6 MB.  GZipping the
  /// file reduces it to 0.5 MB.
  ///
  @override
  File getFilename(Date asOfDate, {String extension = 'json'}) {
    if (extension == 'csv') {
      return File('$dir${asOfDate.year}/WW_DALMP_ISO_${yyyymmdd(asOfDate)}.csv.gz');
    } else if (extension == 'json') {
      return File('$dir${asOfDate.year}/WW_DALMP_ISO_${yyyymmdd(asOfDate)}.json.gz');
    } else {
      throw StateError('Unsupported extension $extension');
    }
  }

  /// Insert data into db.  You can pass in several days at once.
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data');
      return Future.value(-1);
    }
    var groups = groupBy(data, (Map e) => e['date']);
    try {
      for (var date in groups.keys) {
        await dbConfig.coll.remove({'date': date});
        await dbConfig.coll.insertAll(groups[date]!);
        print('--->  Inserted ISONE DAM LMPs for day $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  /// Input [file] is always ending in json.  You can use older csv files for
  /// compatibility but if a new download is initiated (after 2022-12-21),
  /// the file will be json.
  ///
  /// Return a Map with elements like this
  /// ```dart
  /// {
  ///   'date': '2022-12-22',
  ///   'ptid': 321,
  ///   'congestion': <num>[...],
  ///   'lmp': <num>[...],
  ///   'marginal_loss: <num>[...],
  /// }
  /// ```
  @override
  List<Map<String, dynamic>> processFile(File file) {
    if (!file.existsSync()) {
      throw ArgumentError('File $file does not exist!');
    }
    if (extension(file.path) != '.gz') {
      throw ArgumentError('File $file needs to be a gzip archive!');
    }
    return switch (extension(file.path, 2)) {
      '.csv.gz' => _processFileCsv(file),
      '.json.gz' => _processFileJson(file),
      _ => throw ArgumentError('Unsupported file type'),
    };
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var out = <String, dynamic>{
      'date': (rows.first['BeginDate'] as String).substring(0, 10),
      'ptid': int.parse(rows.first['Location']['@LocId']),
      'congestion': <double>[],
      'lmp': <double>[],
      'marginal_loss': <double>[],
    };
    var hours = <TZDateTime>{};

    /// Need to check if there are duplicates.  Sometimes the ISO sends
    /// the same data twice see ptid: 38206, date: 2019-05-19.
    for (var row in rows) {
      var hour = TZDateTime.parse(location, row['BeginDate']);
      if (!hours.contains(hour)) {
        /// if duplicate, insert only once
        hours.add(hour);
        out['lmp'].add((row['LmpTotal'] as num).toDouble());
        out['congestion'].add((row['CongestionComponent'] as num).toDouble());
        out['marginal_loss'].add((row['LossComponent'] as num).toDouble());
      }
    }

    return out;
  }

  List<Map<String, dynamic>> _processFileJson(File file) {
    final bytes = file.readAsBytesSync();
    var content = GZipDecoder().decodeBytes(bytes);
    var data = utf8.decoder.convert(content);

    var aux = json.decode(data) as Map;
    late List<Map<String, dynamic>> xs;
    if (aux.containsKey('HourlyLmps')) {
      if (aux['HourlyLmps'] == '') return <Map<String, dynamic>>[];
      xs =
          (aux['HourlyLmps']['HourlyLmp'] as List).cast<Map<String, dynamic>>();
    } else {
      throw ArgumentError('Can\'t find key HourlyLmps, file: ${file.path}');
    }
    var dataByPtids = groupBy(xs, (Map row) => row['Location']['@LocId']);
    return dataByPtids.keys
        .map((ptid) => converter(dataByPtids[ptid]!))
        .toList();
  }

  List<Map<String, dynamic>> _processFileCsv(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    var dataByPtids = groupBy(data, (dynamic row) => row['Location ID']);
    return dataByPtids.keys
        .map((ptid) => _converterCsv(dataByPtids[ptid]!))
        .toList();
  }

  /// Return a Map with elements like this
  /// ```dart
  /// {
  ///   'date': '2022-12-22',
  ///   'ptid': 321,
  ///   'congestion': <num>[...],
  ///   'lmp': <num>[...],
  ///   'marginal_loss: <num>[...],
  /// }
  /// ```
  Map<String, dynamic> _converterCsv(List<Map<String, dynamic>> rows) {
    var out = <String, dynamic>{
      'date': formatDate(rows.first['Date']),
      'ptid': int.parse(rows.first['Location ID']),
      'congestion': <double>[],
      'lmp': <double>[],
      'marginal_loss': <double>[],
    };
    var hours = <TZDateTime>{};

    /// Need to check if there are duplicates.  Sometimes the ISO sends
    /// the same data twice see ptid: 38206, date: 2019-05-19.
    for (var row in rows) {
      var hour = parseHourEndingStamp(row['Date'], row['Hour Ending']);
      if (!hours.contains(hour)) {
        /// if duplicate, insert only once
        hours.add(hour);
        out['lmp'].add((row['Locational Marginal Price'] as num).toDouble());
        out['congestion'].add((row['Congestion Component'] as num).toDouble());
        out['marginal_loss']
            .add((row['Marginal Loss Component'] as num).toDouble());
      }
    }

    return out;
  }

  @override
  Future downloadDay(Date day) async {
    var user = dotenv.env['ISONE_WS_USER']!;
    var pwd = dotenv.env['ISONE_WS_PASSWORD']!;

    var client = HttpClient()
      ..addCredentials(
          Uri.parse(getUrl(day)), '', HttpClientBasicCredentials(user, pwd))
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var request = await client.getUrl(Uri.parse(getUrl(day)));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    var fileName = getFilename(day).path.removeSuffix('.gz');
    if (!Directory(dirname(fileName)).existsSync()) {
      Directory(dirname(fileName)).createSync(recursive: true);
    }
    await response.pipe(File(fileName).openWrite());
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res = await dbConfig.coll.findOne({'date': date.toString()});
    if (res == null || res.isEmpty) return false;
    return true;
  }

  /// Recreate the collection from scratch.
  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
//    List<String> collections = await dbConfig.db.getCollectionNames();
//    if (collections.contains(dbConfig.collectionName))
//      await dbConfig.coll.drop();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'date': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.close();
  }

  Future<Map<String, String?>> lastDay() async {
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'ptid': {'\$eq': 4000}
      }
    });
    pipeline.add({
      '\$group': {
        '_id': 0,
        'lastDay': {'\$max': '\$date'}
      }
    });
    Map res = await dbConfig.coll.aggregate(pipeline);
    return {'lastDay': res['result'][0]['lastDay']};
  }
}
