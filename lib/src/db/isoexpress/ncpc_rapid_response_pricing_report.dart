import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import '../lib_iso_express.dart';

class NcpcRapidResponsePricingReportArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;
  final String reportName = 'NCPC Rapid Response Pricing Opportunity Cost';
  var _setEq = const SetEquality();

  NcpcRapidResponsePricingReportArchive({this.dbConfig, this.dir}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'isoexpress'
      ..collectionName = 'ncpc_rapid_response_opportunity_cost';

    dir ??= baseDir + 'NCPC/RapidResponsePricingOpportunityCost/Raw/';
  }

  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/ncpc/daily?ncpcType=rrp&start=' +
      yyyymmdd(asOfDate);

  File getFilename(Date asOfDate) =>
      File(dir + 'ncpc_rrp_' + yyyymmdd(asOfDate) + '.csv');

  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = rows.first;
    if (!_setEq.equals(row.keys.skip(1).toSet(), {'Operating Day',
      'RRP NCPC Charge', 'RRP Real-Time Load Obligation',
      'RRP NCPC Charge Rate'}))
      throw ArgumentError('Report $reportName has changed format!');

    var date = formatDate(row['Operating Day']);
    row.remove('H');
    row.remove('Operating Day');
    return {'date': date, ...row};
  }

  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    var out = data.map((row) => converter([row])).toList();
    return out;
  }

  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1}, unique: true);
    await dbConfig.db.close();
  }
}
