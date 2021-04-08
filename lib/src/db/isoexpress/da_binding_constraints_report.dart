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
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class DaBindingConstraintsReportArchive {
  ComponentConfig dbConfig;
  String dir;
  final Location location = getLocation('America/New_York');

  DaBindingConstraintsReportArchive({this.dbConfig, this.dir}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'isoexpress'
      ..collectionName = 'binding_constraints';
    dir ??= baseDir + 'GridReports/DaBindingConstraints/Raw/';
  }

  Db get db => dbConfig.db;

  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/dayaheadconstraints/day/' +
      yyyymmdd(asOfDate);

  File getFilename(Date asOfDate) => File(
      dir + 'da_binding_constraints_final_' + yyyymmdd(asOfDate) + '.json');

  Future downloadDay(Date asOfDate) async {
    var _user = dotenv.env['isone_ws_user'];
    var _pwd = dotenv.env['isone_ws_password'];

    var client = HttpClient()
      ..addCredentials(Uri.parse(getUrl(asOfDate)), '',
          HttpClientBasicCredentials(_user, _pwd))
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var request = await client.getUrl(Uri.parse(getUrl(asOfDate)));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    await response.pipe(getFilename(asOfDate).openWrite());
  }

  /// Need to take the unique rows.  On 2018-07-10, there were duplicates!
  List<Map<String, dynamic>> processFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    var xs;
    if ((aux as Map).containsKey('DayAheadConstraints')) {
      if (aux['DayAheadConstraints'] == '') return <Map<String, dynamic>>[];
      xs = aux['DayAheadConstraints']['DayAheadConstraint'] as List;
    }

    var out = <Map<String, dynamic>>[];
    for (Map<String, dynamic> x in xs) {
      // print(x);
      var one = <String, dynamic>{
        'Constraint Name': x['ConstraintName'],
        'Contingency Name': x['ContingencyName'],
        'Interface Flag': x['InterfaceFlag'],
        'Marginal Value': x['MarginalValue'],
        'hourBeginning': TZDateTime.parse(location, x['BeginDate']).toUtc(),
        'market': 'DA',
        'date': (x['BeginDate'] as String).substring(0, 10),
      };
      out.add(one);
    }

    return unique(out).cast<Map<String, dynamic>>();
  }

  /// Insert data into db
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    var groups = groupBy(data, (e) => e['date']);
    try {
      for (var date in groups.keys) {
        await dbConfig.coll.remove({'date': date});
        await dbConfig.coll.insertAll(groups[date]);
        print('--->  Inserted DA binding constraints for day ${date}');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx ' + e.toString());
      return 1;
    }
    ;
  }

  Future<Null> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'Constraint Name': 1, 'market': 1});
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'date': 1, 'market': 1});
    await dbConfig.db.close();
  }
}
