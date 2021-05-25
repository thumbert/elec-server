library db.isoexpress.ncpc_generator_performance_audit_report;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import '../lib_iso_express.dart';

class NcpcGpaReportArchive extends DailyIsoExpressReport {
  @override
  final String reportName = 'Generator Performance Audit Net Commitment Period Compensation Report';
  final _setEq = const SetEquality();
  final _columnNames = {'H', 'Operating Day', 'GPA NCPC Charge',
    'GPA Real-Time Load Obligation',	'GPA NCPC Charge Rate',
  };

  NcpcGpaReportArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
          host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'ncpc');
    this.dbConfig = dbConfig;
    dir ??= baseDir + 'NCPC/GpaCost/Raw/';
    this.dir = dir;
  }

  String getUrl(Date? asOfDate) =>
      'https://www.iso-ne.com/transform/csv/ncpc/daily?ncpcType=GPA&start=' +
          yyyymmdd(asOfDate);

  File getFilename(Date? asOfDate) =>
      File(dir + 'ncpc_gpa_' + yyyymmdd(asOfDate) + '.csv');

  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = rows.first; // one row at at time
    if (!_setEq.equals(row.keys.toSet(), _columnNames))
      throw ArgumentError('Report $reportName has changed format!');
    var date = formatDate(row['Operating Day']);
    row.remove('H');
    row.remove('Operating Day');
    return {'date': date, 'ncpcType': 'GPA', ...row};
  }

  /// Each file has only one row.
  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    var out = data.map((row) => converter([row])).toList();
    return out;
  }

  Future<Null> setupDb() async {
    await dbConfig.db.open();
    var collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.remove({'ncpcType': 'GPA'});
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1, 'ncpcType': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'ncpcType': 1});
    await dbConfig.db.close();
  }
}
