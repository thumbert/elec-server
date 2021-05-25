library db.webservices.asset_ncpc;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import '../lib_iso_express.dart';
//import 'package:dotenv/dotenv.dart' as dotenv;

class AssetNcpcArchive {
  late ComponentConfig dbConfig;
  String? dir;
  final Location location = getLocation('America/New_York');

  AssetNcpcArchive({ComponentConfig? dbConfig, this.dir}) {
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1', dbName: 'isone_ws', collectionName: 'asset_ncpc');
    }
    dir ??= baseDir + 'webservices/Raw/';
  }

  /// See documentation at
  /// https://www.iso-ne.com/static-assets/documents/2017/06/webservices_documentation.xlsx
  String getUrl(Month month) =>
      'https://webservices.iso-ne.com/api/v1.1/monthlyassetncpc/' +
      month.toIso8601String().replaceAll('-', '');

  File getFilename(Month month) =>
      File(dir! + 'asset_ncpc_' + month.toIso8601String() + '.json');

  Future downloadMonth(Month month) async {
    var _user = Platform.environment['isone_ws_user']!;
    var _pwd = Platform.environment['isone_ws_password']!;

    var client = HttpClient()
      ..addCredentials(
          Uri.parse(getUrl(month)), '', HttpClientBasicCredentials(_user, _pwd))
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var request = await client.getUrl(Uri.parse(getUrl(month)));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    await response.pipe(getFilename(month).openWrite());
  }

  // List<Map<String, dynamic>> processFile(File file) {
  //   var aux = json.decode(file.readAsStringSync());
  //   var xs;
  //   if ((aux as Map).containsKey('DayAheadConstraints')) {
  //     if (aux['DayAheadConstraints'] == '') return <Map<String, dynamic>>[];
  //     xs = aux['DayAheadConstraints']['DayAheadConstraint'] as List;
  //   }
  //
  //   var out = <Map<String, dynamic>>[];
  //   for (Map<String, dynamic> x in xs) {
  //     // print(x);
  //     var one = <String, dynamic>{
  //       'Constraint Name': x['ConstraintName'],
  //       'Contingency Name': x['ContingencyName'],
  //       'Interface Flag': x['InterfaceFlag'],
  //       'Marginal Value': x['MarginalValue'],
  //       'hourBeginning': TZDateTime.parse(location, x['BeginDate']).toUtc(),
  //       'market': 'DA',
  //       'date': (x['BeginDate'] as String).substring(0, 10),
  //     };
  //     out.add(one);
  //   }
  //
  //   return unique(out).cast<Map<String, dynamic>>();
  // }

  // /// Insert data into db
  // Future<int> insertData(List<Map<String, dynamic>> data) async {
  //   if (data.isEmpty) return Future.value(null);
  //   var groups = groupBy(data, (e) => e['date']);
  //   try {
  //     for (var date in groups.keys) {
  //       await dbConfig.coll.remove({'date': date});
  //       await dbConfig.coll.insertAll(groups[date]);
  //       print('--->  Inserted DA binding constraints for day ${date}');
  //     }
  //     return 0;
  //   } catch (e) {
  //     print('xxxx ERROR xxxx ' + e.toString());
  //     return 1;
  //   }
  //   ;
  // }
  //
  // Future<Null> setupDb() async {
  //   await dbConfig.db.open();
  //   await dbConfig.db.createIndex(dbConfig.collectionName,
  //       keys: {'Constraint Name': 1, 'market': 1});
  //   await dbConfig.db
  //       .createIndex(dbConfig.collectionName, keys: {'date': 1, 'market': 1});
  //   await dbConfig.db.close();
  // }
}
