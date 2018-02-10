library db.mis.sd_rtload;

import 'dart:async';
import 'dart:io';
import 'package:func/func.dart';
import '../config.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';


class SdRtloadArchive extends mis.MisReportArchive {
  ComponentConfig dbConfig;

  SdRtloadArchive(this.dbConfig) {
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'mis'
        ..collectionName = 'sd_rtload';
    }
  }

  Func1<List<Map>, Map> converter = (List<Map> rows) {
    Map row = {};
    row['date'] = formatDate(rows.first['Date']);
    row['ptid'] = int.parse(rows.first['Location ID']);
    row['hourBeginning'] = [];
    row['congestion'] = [];
    row['lmp'] = [];
    row['marginal_loss'] = [];
    rows.forEach((e) {
      row['hourBeginning'].add(parseHourEndingStamp(e['Date'], e['Hour Ending']));
      row['lmp'].add(e['Locational Marginal Price']);
      row['congestion'].add(e['Congestion Component']);
      row['marginal_loss'].add(e['Marginal Loss Component']);
    });
    return row;
  };

  @override
  List<List<Map>> processFile(File file) {
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    data.forEach((row) => converter([row]));
    /// add the report date
    //var date =
    return [data];
  }

  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName)) await dbConfig.coll.drop();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1, 'Asset ID': 1, 'Contingency Name': 1, 'market': 1}, unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'Constraint Name': 1, 'market': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1, 'market': 1});
    await dbConfig.db.close();
  }

  @override
  Future<Null> updateDb() {
    // TODO: implement updateDb
  }

  Map _groupBy(Iterable x, Function f) {
    Map result = new Map();
    x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
    return result;
  }


}