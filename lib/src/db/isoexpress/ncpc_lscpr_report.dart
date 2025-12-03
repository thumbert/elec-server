import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import '../lib_iso_express.dart';

class NcpcLscprReportArchive extends DailyIsoExpressReport {
  final _setEq = const SetEquality();
  final _columnNames = {
    'H',
    'Operating Day',
    'Region ID',
    'Region Name',
    'DA LSCPR NCPC Charge',
    'DA NCPC Load Obligation',
    'DA LSCPR NCPC Rate',
    'RT LSCPR NCPC Charge',
    'RT NCPC Load Obligation',
    'RT LSCPR NCPC Rate',
  };

  NcpcLscprReportArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'ncpc');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}NCPC/LscprCost/Raw/';
    this.dir = dir;
    reportName =
        'Local Second Contingency Net Commitment Period Compensation Report';
  }

  @override
  String getUrl(Date? asOfDate) =>
      'https://www.iso-ne.com/transform/csv/ncpc/daily?ncpcType=lscpr&start=${yyyymmdd(asOfDate)}';

  @override
  File getFilename(Date? asOfDate) =>
      File('${dir}ncpc_lscpr_${yyyymmdd(asOfDate)}.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = rows.first; // one row at at time
    if (!_setEq.equals(row.keys.toSet(), _columnNames)) {
      throw ArgumentError('Report $reportName has changed format!');
    }
    var date = formatDate(row['Operating Day']);
    row.remove('H');
    row.remove('Operating Day');
    return {'date': date, 'ncpcType': 'LSCPR', ...row};
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    var out = data.map((row) => converter([row])).toList();
    return out;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    var collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName)) {
      await dbConfig.coll.remove({'ncpcType': 'LSCPR'});
    }
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'date': 1, 'ncpcType': 1});
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'ncpcType': 1});
    await dbConfig.db.close();
  }
}
