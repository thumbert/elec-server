library db.isoexpress.fuelmix_report_archive;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class FuelMixReportArchive extends DailyIsoExpressReport {
  /// Report gets finalized every day at midnight, and published throughout the
  /// day.
  FuelMixReportArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(host: '127.0.0.1', dbName: 'isoexpress',
        collectionName: 'fuel_mix');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}GridReports/FuelMix/Raw/';
    this.dir = dir;
    reportName = 'Dispatch Fuel Mix Report';
  }

  @override
  String getUrl(Date? asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/genfuelmix/day/${yyyymmdd(asOfDate)}';

  @override
  File getFilename(Date asOfDate) => File(
      '${dir}genfuelmix_${yyyymmdd(asOfDate)}.json');

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
    await response.pipe(getFilename(day).openWrite());
  }


  /// Return one document for one fuel category per day.
  /// Aggregate all intra hour observations into one average value.
  ///
  /// ```dart
  /// {
  ///   'date': '2020-01-01',
  ///   'category': 'Hydro',
  ///   'mw': [671, 668, ...], // 24 values
  ///   'marginalFlag': [true, false, false, ...], // 24 values
  /// }
  /// ```
  @override
  List<Map<String, dynamic>> processFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    late List<Map<String,dynamic>> xs;
    if ((aux as Map).containsKey('GenFuelMixes')) {
      if (aux['GenFuelMixes'] == '') return <Map<String, dynamic>>[];
      xs = (aux['GenFuelMixes']['GenFuelMix'] as List)
          .cast<Map<String, dynamic>>();
    } else {
      throw ArgumentError('Can\'t find key GenFuelMixes.  Check file!');
    }

    var date = (xs.first['BeginDate'] as String).substring(0,10);
    var ts0 = TimeSeries<num>.fill(Date.parse(date, location: location).hours(), 0);
    var bool0 = TimeSeries.fill(Date.parse(date, location: location).hours(), false);

    /// Split the data by fuel category
    var groups = groupBy(xs, (Map e) => e['FuelCategory'] as String);

    var out = <Map<String, dynamic>>[];
    for (var fuelType in groups.keys) {
      /// hourly average, some hours may be missing
      var mwData = toHourly(groups[fuelType]!.map((e) =>
          IntervalTuple<num>(Hour.beginning(TZDateTime.parse(location, e['BeginDate'])), e['GenMw'])), mean);
      var mw = ts0.merge(mwData, joinType: JoinType.Left, f: (x,y) {
        if (y == null) {
          return 0;
        } else {
          return y;
        }
      }).values.toList();
      var marginalFlag = toHourly(groups[fuelType]!.map((e) =>
          IntervalTuple<String>(Hour.beginning(TZDateTime.parse(location, e['BeginDate'])), e['MarginalFlag'])),
              (xs) => xs.any((e) => e == 'Y'));
      var isMarginal = bool0.merge(marginalFlag, joinType: JoinType.Left, f: (x,y) {
        if (y == null) {
          return 0;
        } else {
          return y;
        }
      }).values.toList();
      out.add({
        'date': date,
        'category': fuelType,
        'mw': mw,
        'isMarginal': isMarginal,
      });
    }

    return out;
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    return {};
  }

  @override
  Future insertData(List<Map<String,dynamic>> data) async {
    var doc = data.first;
    await dbConfig.coll.remove({'date': doc['date']});
    return dbConfig.coll
        .insertAll(data)
        .then((_) => print('--->  Inserted ISONE FuelMix data for ${doc['date']} successfully'))
        .catchError((e) => print(' XXXX $e'));
  }

  /// Create the collection from scratch.
  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'category': 1, 'date': 1}, unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1});
    await dbConfig.db.close();
  }

}