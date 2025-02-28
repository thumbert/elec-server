library db.isoexpress.da_binding_constraints_report;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import '../lib_iso_express.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class DaBindingConstraintsReportArchive extends DailyIsoExpressReport {
  DaBindingConstraintsReportArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'isoexpress',
        collectionName: 'binding_constraints');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}GridReports/DaBindingConstraints/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Binding Constraints Report';
  }

  Db get db => dbConfig.db;

  @override
  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/dayaheadconstraints/day/${yyyymmdd(asOfDate)}';

  @override
  File getFilename(Date asOfDate) =>
      File('${dir}da_binding_constraints_final_${yyyymmdd(asOfDate)}.json');

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
    await response.pipe(getFilename(day).openWrite());
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var constraints = <Map<String, dynamic>>[];
    for (var row in rows) {
      constraints.add({
        'Constraint Name': row['ConstraintName'],
        'Contingency Name': row['ContingencyName'],
        'Interface Flag': row['InterfaceFlag'],
        'Marginal Value': row['MarginalValue'],
        'hourBeginning': TZDateTime.parse(location, row['BeginDate']).toUtc(),
      });
    }

    /// Need to take the unique rows.  On 2018-07-10, there were duplicates!
    var uConstraints = unique(constraints);

    return {
      'market': 'DA',
      'date': (rows.first['BeginDate'] as String).substring(0, 10),
      'constraints': uConstraints,
    };
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    late List<Map<String, dynamic>> xs;
    if ((aux as Map).containsKey('DayAheadConstraints')) {
      var cs = aux['DayAheadConstraints'];
      if (cs == '') return <Map<String, dynamic>>[];
      if (cs is Map && cs.isEmpty) return <Map<String, dynamic>>[];
      xs = (aux['DayAheadConstraints']['DayAheadConstraint'] as List)
          .cast<Map<String, dynamic>>();
    } else {
      throw ArgumentError('Can\'t find key DayAheadConstraints.  Check file!');
    }

    return [converter(xs)];
  }

  /// Insert data into db
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data to insert');
      return Future.value(-1);
    }
    var groups = groupBy(data, (dynamic e) => e['date']);
    try {
      for (var date in groups.keys) {
        await dbConfig.coll.remove({'date': date});
        await dbConfig.coll.insertAll(groups[date]!);
        print('--->  Inserted DA binding constraints for day $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'market': 1, 'date': 1});
    await dbConfig.db.close();
  }
}
