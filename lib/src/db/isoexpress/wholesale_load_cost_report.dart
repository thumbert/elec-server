library db.isoexpress.monthly_wholesale_load_cost;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';
import 'package:timezone/timezone.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import '../lib_iso_express.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class WholesaleLoadCostReportArchive extends IsoExpressReport {
  @override
  ComponentConfig dbConfig;
  String dir;
  @override
  final String reportName = 'Monthly Wholesale Load Cost Report';
  static final location = getLocation('America/New_York');

  WholesaleLoadCostReportArchive({this.dbConfig, this.dir}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'isoexpress'
      ..collectionName = 'wholesale_load_cost';
    dir ??= baseDir + 'WholesaleLoadCost/Raw/';
  }

  /// Data is also available as webservices, for example
  /// https://webservices.iso-ne.com/api/v1.1/whlsecost/hourly/month/202007/location/4004
  /// Use 4000 for the entire ISONE territory.
  /// It is also available as CSV files from
  /// https://www.iso-ne.com/isoexpress/web/reports/load-and-demand/-/tree/hourly-wholesale-load-cost-report
  String getUrl(Month month, int ptid) =>
      'https://webservices.iso-ne.com/api/v1.1/whlsecost/hourly/month/'
          '${month.toIso8601String().replaceAll('-', '')}/location/$ptid';

  File getFilename(Month month, int ptid) => File(dir +
      'whlsecost_hourly_$ptid' +
      '_' +
      '${month.toIso8601String().replaceAll('-', '')}.json');

  Future<void> downloadFile(Month month, int ptid) async {
    var _user = dotenv.env['isone_ws_user'];
    var _pwd = dotenv.env['isone_ws_password'];

    var client = HttpClient()
      ..addCredentials(Uri.parse(getUrl(month, ptid)), '',
          HttpClientBasicCredentials(_user, _pwd))
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var request = await client.getUrl(Uri.parse(getUrl(month, ptid)));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    await response.pipe(getFilename(month, ptid).openWrite());

  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    List xs;
    if ((aux as Map).containsKey('WhlseCosts')) {
      if (aux['WhlseCosts'] == '') return <Map<String, dynamic>>[];
      xs = aux['WhlseCosts']['WhlseCost'] as List;
    }
    var data = xs.map((e) {
      return <String,dynamic>{
        'date': (e['BeginDate'] as String).substring(0, 10),
        'hourBeginning': e['BeginDate'] as String,
        'rtLoad': e['RTLO'] as num,
      };
    }).toList();
    data.sortBy((e) => e['hourBeginning'] as String);
    var ptid = int.parse(xs.first['Location']['@LocId']);
    var groups = groupBy(data, (e) => e['date'] as String);

    var out = <Map<String, dynamic>>[];
    for (var date in groups.keys) {
      var group = groups[date];
      out.add({
        'date': date,
        'ptid': ptid,
        'rtLoad': group.map((e) => e['rtLoad']).toList()
      });
    }

    return out;
  }

  /// Can insert more than one zone and date at a time.
  @override
  Future insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);

    /// split data by ptid and date
    var groups =
        groupBy(data, (e) => Tuple2(e['ptid'] as int, e['date'] as String));
    try {
      for (var key in groups.keys) {
        await dbConfig.coll.remove({
          'ptid': key.item1,
          'date': key.item2,
        });
        await dbConfig.coll.insertAll(groups[key]);
      }
      var month = (data.first['date'] as String).substring(0, 7);
      print('--->  Inserted $reportName for month '
          '$month, ptid ${data.first['ptid']}');
    } catch (e) {
      print('XXX ' + e.toString());
    }
  }

  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'date': 1,
        },
        unique: true);
    await dbConfig.db.close();
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    // TODO: implement converter
    throw UnimplementedError();
  }
}
