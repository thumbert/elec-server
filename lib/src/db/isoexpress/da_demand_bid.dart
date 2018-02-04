library db.isoexpress.da_demand_bid;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaDemandBidArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;

  DaDemandBidArchive({this.dbConfig, this.dir}) {
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'da_demand_bid';
    }
    if (dir == null)
      dir = baseDir + 'PricingReports/DaDemandBid/Raw/';
  }
  String reportName = 'Day-Ahead Energy Market Demand Historical Demand Bid Report';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/static-transform/csv/histRpts/da-dmd-bid/' +
          'hbdayaheaddemandbid_' + yyyymmdd(asOfDate) + '.csv';
  File getFilename(Date asOfDate) =>
      new File(dir + 'hbdayaheaddemandbid_' + yyyymmdd(asOfDate) + '.csv');

  /// [rows] has the data for all the hours of the day for one location id
  Map converter(List<Map> rows) {
    Map row = {};
    /// daily info
    row['date'] = formatDate(rows.first['Day']);
    row['Masked Lead Participant ID'] = rows.first['Masked Lead Participant ID'];
    row['Masked Location ID'] = rows.first['Masked Location ID'];
    row['Location Type'] = rows.first['Location Type'];
    row['Bid Type'] = rows.first['Bid Type'];
    row['Bid ID'] = rows.first['Bid ID'];

    /// hourly info
    row['hours'] = [];
    rows.forEach((Map hour) {
      Map aux = {};
      String he = stringHourEnding(hour['Hour']);
      aux['hourBeginning'] = parseHourEndingStamp(hour['Day'], he);
      /// add the non empty price/quantity pairs
      var pricesHour = [];
      var quantitiesHour = [];
      for (int i = 1; i <= 10; i++) {
        if (!(hour['Segment $i MW'] is num))
          break;
        quantitiesHour.add(hour['Segment $i MW']);
        pricesHour.add(hour['Segment $i Price']);
      }
      aux['price'] = pricesHour;
      aux['quantity'] = quantitiesHour;
      row['hours'].add(aux);
    });
    return row;
  }

  List<Map> processFile(File file) {
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    Map dataByBidId = _groupBy(data, (row) => row['Bid ID']);
    return dataByBidId.keys.map((ptid) => converter(dataByBidId[ptid])).toList();
  }

  /// Recreate the collection from scratch.
  setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'date': 1,
          'Bid ID': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'date': 1,
          'Masked Lead Participant ID': 1,
          'Masked Location ID': 1,
        });
    await dbConfig.db.close();
  }

  Future<Map<String,String>> lastDay() async {
    List pipeline = [];
    pipeline.add({'\$group': {
      '_id': 0,
      'lastDay': {'\$max': '\$date'}}});
    Map res = await dbConfig.coll.aggregate(pipeline);
    return {'lastDay': res['result'][0]['lastDay']};
  }

  /// return the last day of the fourth month before the current month.
  Date lastDayAvailable() {
    Month m3 = Month.current().subtract(3);
    return new Date(m3.year, m3.month,1).previous;
  }
  Future<Null> deleteDay(Date day) async {
    return await dbConfig.coll.remove(where.eq('date', day.toString()));
  }


}


Map _groupBy(Iterable x, Function f) {
  Map result = new Map();
  x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
  return result;
}
