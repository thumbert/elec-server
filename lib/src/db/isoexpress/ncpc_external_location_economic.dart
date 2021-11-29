library db.isoexpress.ncpc_external_location_economic;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import '../lib_iso_express.dart';

class NcpcExternalLocationEconomicArchive extends DailyIsoExpressReport {
  @override
  final String reportName = 'External Location Economic Net Commitment Period Compensation';
  final _setEq = const SetEquality();
  final _columnNames = {'H', 'Operating Day',
    'Trading Interval',	'External Node ID',	'External Node Name',
    'NCPC Credit Type',	'DA Economic NCPC Charge',
    'DA Load Obligation at External Node',
    'DA Generation Obligation at External Node',
    'DA Economic NCPC Charge Rate',
  };

  NcpcExternalLocationEconomicArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
          host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'ncpc');
    this.dbConfig = dbConfig;
    dir ??= baseDir + 'NCPC/ExternalLocationEconomic/Raw/';
    this.dir = dir;
  }

  @override
  String getUrl(Date? asOfDate) =>
      'https://www.iso-ne.com/transform/csv/ncpc/daily?ncpcType=extloceconomic&start=' +
          yyyymmdd(asOfDate);

  @override
  File getFilename(Date? asOfDate) =>
      File(dir + 'ncpc_extloceconomic_' + yyyymmdd(asOfDate) + '.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = rows.first;
    if (!_setEq.equals(row.keys.toSet(), _columnNames)) {
      throw ArgumentError('Report $reportName for ${row['Operating Day']} has changed format!');
    }
    var date = formatDate(row['Operating Day']);
    row.remove('H');
    row.remove('Operating Day');
    return {'date': date, 'ncpcType': 'External Location Economic', ...row};
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
    List<String?> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName)) {
      await dbConfig.coll.drop();
    }
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1, 'ncpcType': 1}, unique: true);
    await dbConfig.db.close();
  }
}
