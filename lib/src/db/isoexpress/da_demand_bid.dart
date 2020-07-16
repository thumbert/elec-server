library db.isoexpress.da_demand_bid;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaDemandBidArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;
  Location location;

  DaDemandBidArchive({this.dbConfig, this.dir}) {
    dbConfig ??= new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'da_demand_bid';
    dir ??= baseDir + 'PricingReports/DaDemandBid/Raw/';
    location = getLocation('America/New_York');
  }
  String reportName = 'Day-Ahead Energy Market Demand Historical Demand Bid Report';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/static-transform/csv/histRpts/da-dmd-bid/' +
          'hbdayaheaddemandbid_' + yyyymmdd(asOfDate) + '.csv';
  File getFilename(Date asOfDate) =>
      new File(dir + 'hbdayaheaddemandbid_' + yyyymmdd(asOfDate) + '.csv');

  /// [rows] has the data for all the hours of the day for one location id
  Map<String,dynamic> converter(List<Map<String,dynamic>> rows) {
    var row = <String,dynamic>{};
    /// daily info
    row['date'] = formatDate(rows.first['Day']);
    row['Masked Lead Participant ID'] = rows.first['Masked Lead Participant ID'];
    row['Masked Location ID'] = rows.first['Masked Location ID'];
    row['Location Type'] = rows.first['Location Type'];
    row['Bid Type'] = rows.first['Bid Type'];
    row['Bid ID'] = rows.first['Bid ID'];

    /// hourly info
    row['hours'] = <Map<String,dynamic>>[];
    rows.forEach((Map hour) {
      var aux = <String,dynamic>{};
      String he = stringHourEnding(hour['Hour']);
      var hb = parseHourEndingStamp(hour['Day'], he);
      aux['hourBeginning'] = TZDateTime.fromMillisecondsSinceEpoch(location,
          hb.millisecondsSinceEpoch).toIso8601String();
      /// add the non empty price/quantity pairs
      var pricesHour = <num>[];
      var quantitiesHour = <num>[];
      for (int i = 1; i <= 10; i++) {
        if (!(hour['Segment $i MW'] is num))
          break;
        quantitiesHour.add(hour['Segment $i MW']);
        if (!(hour['Segment $i Price'] is num))
          break;
        pricesHour.add(hour['Segment $i Price']);
      }
      // fixed demand bids have no prices
      if (pricesHour.isNotEmpty) aux['price'] = pricesHour;
      aux['quantity'] = quantitiesHour;
      row['hours'].add(aux);
    });
    return row;
  }

  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.length == 0) return Future.value(0);
    var day = data.first['date'];
    await dbConfig.coll.remove({'date': day});
    try {
      await dbConfig.coll.insertAll(data);
    } catch (e) {
      print(' XXXX ' + e.toString());
      return Future.value(1);
    }
    print('--->  SUCCESS inserting masked DA Demand Bids for ${day}');
    return Future.value(0);
  }


  List<Map<String,dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String,dynamic>>[];
    var dataByBidId = groupBy(data, (row) => row['Bid ID']);
    return dataByBidId.keys.map((ptid) => converter(dataByBidId[ptid])).toList();
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res = await dbConfig.coll.findOne({'date': date.toString()});
    if (res == null || res.isEmpty) return false;
    return true;
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

  Future<Null> deleteDay(Date day) async {
    return await dbConfig.coll.remove(where.eq('date', day.toString()));
  }


}


