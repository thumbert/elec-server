library db.isoexpress.rt_lmp_hourly;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:dotenv/dotenv.dart' as dotenv;


class RtLmpHourlyArchive extends DailyIsoExpressReport {

  RtLmpHourlyArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
          host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'rt_lmp_hourly');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}PricingReports/RtLmpHourly/Raw/';
    this.dir = dir;
    reportName = 'Real-Time Energy Market Hourly LMP Report';
  }

  // @override
  // String getUrl(Date? asOfDate) =>
  //     'https://www.iso-ne.com/static-transform/csv/histRpts/rt-lmp/lmp_rt_final_${yyyymmdd(asOfDate)}.csv';

  @override
  String getUrl(Date? asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/hourlylmp/rt/final/day/${yyyymmdd(asOfDate)}';

  @override
  File getFilename(Date asOfDate, {String extension = 'json'}) {
    if (extension == 'csv') {
      return File('${dir}lmp_rt_final_${yyyymmdd(asOfDate)}.csv');
    } else if (extension == 'json') {
      return File('${dir}lmp_rt_final_${yyyymmdd(asOfDate)}.json');
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
        print('--->  Inserted ISONE RT LMPs for day $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }


  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = <String, dynamic>{};
    row['date'] = (rows.first['BeginDate'] as String).substring(0,10);
    row['ptid'] = int.parse(rows.first['Location']['@LocId']);
    row['congestion'] = <num>[];
    row['lmp'] = <num>[];
    row['marginal_loss'] = <num>[];
    for (var e in rows) {
      row['lmp'].add(e['LmpTotal']);
      row['congestion'].add(e['CongestionComponent']);
      row['marginal_loss'].add(e['LossComponent']);
    }
    return row;
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
  @override
  List<Map<String, dynamic>> processFile(File file) {
    if (file.path.endsWith('csv') && file.existsSync()) {
      return _processFileCsv(file);
    } else if (file.path.endsWith('json') && file.existsSync()) {
      return _processFileJson(file);
    } else {
      throw ArgumentError('File $file does not exist!');
    }
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

  Map<String, dynamic> _converterCsv(List<Map<String, dynamic>> rows) {
    var row = <String, dynamic>{};
    row['date'] = formatDate(rows.first['Date']);
    row['ptid'] = int.parse(rows.first['Location ID']);
    row['congestion'] = [];
    row['lmp'] = [];
    row['marginal_loss'] = [];
    for (var e in rows) {
      row['lmp'].add(e['Locational Marginal Price']);
      row['congestion'].add(e['Congestion Component']);
      row['marginal_loss'].add(e['Marginal Loss Component']);
    }
    return row;
  }

  @override
  Future downloadDay(Date day) async {
    var user = dotenv.env['ISONE_WS_USER']!;
    var pwd = dotenv.env['ISONE_WS_PASSWORD']!;

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
    await response.pipe(getFilename(day).openWrite());
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
    // List<String?> collections = await dbConfig.db.getCollectionNames();
    // if (collections.contains(dbConfig.collectionName))
    //   await dbConfig.coll.drop();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'date': 1,
        },
        unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'date': 1});
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

  Date lastDayAvailable() => Date.today(location: UTC).next;
}
