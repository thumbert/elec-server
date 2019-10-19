library db.isoexpress.ncpc_economic_report;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import '../lib_iso_express.dart';

class NcpcEconomicReportArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;
  final String reportName = 'Economic Net Commitment Period Compensation Report';
  var _setEq = const SetEquality();
  var _columnNames = {'H', 'Day',
    'Day-Ahead NCPC Charge',	'Day-Ahead NCPC Load Obligation',
    'Day-Ahead NCPC Charge Rate',	'Real-Time NCPC Charge',
    'Real-Time NCPC Deviations',	'Real-Time NCPC Charge Rate',
  };

  NcpcEconomicReportArchive({this.dbConfig, this.dir}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'isoexpress'
      ..collectionName = 'ncpc';

    dir ??= baseDir + 'NCPC/EconomicCost/Raw/';
  }

  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/ncpc/daily?ncpcType=economic&start=' +
          yyyymmdd(asOfDate);

  File getFilename(Date asOfDate) =>
      File(dir + 'ncpc_economic_' + yyyymmdd(asOfDate) + '.csv');

  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = rows.first; // one row at at time
    if (!_setEq.equals(row.keys.toSet(), _columnNames))
      throw ArgumentError('Report $reportName has changed format!');
    var date = formatDate(row['Day']);
    row.remove('H');
    row.remove('Day');
    return {'date': date, 'ncpcType': 'Economic', ...row};
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
      await dbConfig.coll.remove({'ncpcType': 'Economic'});
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1, 'ncpcType': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'ncpcType': 1});
    await dbConfig.db.close();
  }
}
