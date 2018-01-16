import 'dart:io';
import 'dart:async';
import 'package:func/func.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import '../lib_iso_express.dart';

class NcpcRapidResponsePricingReportArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;

  NcpcRapidResponsePricingReportArchive({this.dbConfig, this.dir}) {
    if (dbConfig == null) {
      this.dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'ncpc_rapid_response_opportunity_cost';
    }
    if (dir == null)
      dir = baseDir + 'NCPC/RapidResponsePricingOpportunityCost/Raw/';
  }
  String reportName = 'NCPC Rapid Response Pricing Opportunity Cost';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/ncpc/daily?ncpcType=rrp&start=' +
      yyyymmdd(asOfDate);
  File getFilename(Date asOfDate) =>
      new File(dir + 'ncpc_rrp_' + yyyymmdd(asOfDate) + '.csv');

  Func1<List<Map>, Map> converter = (List<Map> rows) {
    Map row = rows.first;
    row['Operating Day'] = formatDate(row['Operating Day']);
    row.remove('H');
    return row;
  };

  List<Map> processFile(File file) {
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    data.forEach((row) => converter([row]));
    return data;
  }

  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'Operating Day': 1}, unique: true);
    await dbConfig.db.close();
  }

  Future<Map<String, String>> lastDay() async {
    List pipeline = [];
    pipeline.add({
      '\$group': {
        '_id': 0,
        'lastDay': {'\$max': '\$Operating Day'}
      }
    });
    Map res = await dbConfig.coll.aggregate(pipeline);
    return {'lastDay': res['result'][0]['lastDay']};
  }

  Date lastDayAvailable() => Date.today().subtract(4);
  Future<Null> deleteDay(Date day) async {
    return await dbConfig.coll
        .remove(where.eq('Operating Day', day.toString()));
  }
}
