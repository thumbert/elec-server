library db.isoexpress.da_lmp_hourly;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
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

  @override
  File getFilename(Date asOfDate) {
      return File('${dir}WW_DALMP_ISO_${yyyymmdd(asOfDate)}.json');
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
      // try and see if the csv file is there (support legacy format)
      var fileCsv = File(file.path.replaceAll('json', 'csv'));
      if (fileCsv.existsSync()) {
        return _processFileCsv(fileCsv);
      } else {
        throw ArgumentError('Neither json or csv ${basename(file.path)} file exists!');
      }
    }
    return _processFileJson(file);
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var out = <String, dynamic>{
      'date': (rows.first['BeginDate'] as String).substring(0,10),
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
    var aux = json.decode(file.readAsStringSync()) as Map;
    late List<Map<String,dynamic>> xs;
    if (aux.containsKey('HourlyLmps')) {
      if (aux['HourlyLmps'] == '') return <Map<String,dynamic>>[];
      xs = (aux['HourlyLmps']['HourlyLmp'] as List).cast<Map<String,dynamic>>();
    } else {
      throw ArgumentError('Can\'t find key HourlyLmps in file $file');
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
        out['marginal_loss'].add((row['Marginal Loss Component'] as num).toDouble());
      }
    }

    return out;
  }

  @override
  Future downloadDay(Date day) async {
    var user = dotenv.env['isone_ws_user']!;
    var pwd = dotenv.env['isone_ws_password']!;

    var client = HttpClient()
      ..addCredentials(Uri.parse(getUrl(day)), '',
          HttpClientBasicCredentials(user, pwd))
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var request = await client.getUrl(Uri.parse(getUrl(day)));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    var file = File('${dir}WW_DALMP_ISO_${yyyymmdd(day)}.json');
    await response.pipe(file.openWrite());
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
