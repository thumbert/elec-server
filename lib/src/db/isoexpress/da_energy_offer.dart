library db.isoexpress.da_energy_offer;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaEnergyOfferArchive extends DailyIsoExpressReport {
  static final List<String> _unitStates = [
    'UNAVAILABLE',
    'MUST_RUN',
    'ECONOMIC'
  ];

  DaEnergyOfferArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'isoexpress',
        collectionName: 'da_energy_offer');
    this.dbConfig = dbConfig;
    dir ??= baseDir + 'PricingReports/DaEnergyOffer/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Energy Market Historical Offer Report';
  }

  mongo.Db get db => dbConfig.db;

  @override
  String getUrl(Date? asOfDate) =>
      'https://www.iso-ne.com/static-transform/csv/histRpts/da-energy-offer/'
          'hbdayaheadenergyoffer_' +
      yyyymmdd(asOfDate) +
      '.csv';
  @override
  File getFilename(Date? asOfDate) =>
      File(dir + 'hbdayaheadenergyoffer_' + yyyymmdd(asOfDate) + '.csv');

  /// [rows] has the data for all the hours of the day for one asset
  @override
  Map<String, dynamic> converter(List<Map> rows) {
    var row = <String, dynamic>{};

    /// daily info
    row['date'] = formatDate(rows.first['Day']);
    row['Masked Lead Participant ID'] =
        rows.first['Masked Lead Participant ID'];
    row['Masked Asset ID'] = rows.first['Masked Asset ID'];
    row['Must Take Energy'] = rows.first['Must Take Energy'];
    row['Maximum Daily Energy Available'] =
        rows.first['Maximum Daily Energy Available'];
    row['Unit Status'] = rows.first['Unit Status'];
    row['Claim 10'] = rows.first['Claim 10'];
    row['Claim 30'] = rows.first['Claim 30'];

    /// hourly info
    row['hours'] = [];
    for (var hour in rows) {
      var aux = <String, dynamic>{};
      var utc = parseHourEndingStamp(hour['Day'], hour['Trading Interval']);
      aux['hourBeginning'] = TZDateTime.fromMicrosecondsSinceEpoch(
              location, utc.microsecondsSinceEpoch)
          .toIso8601String();
      aux['Economic Maximum'] = hour['Economic Maximum'];
      aux['Economic Minimum'] = hour['Economic Minimum'];
      aux['Cold Startup Price'] = hour['Cold Startup Price'];
      aux['Intermediate Startup Price'] = hour['Intermediate Startup Price'];
      aux['Hot Startup Price'] = hour['Hot Startup Price'];
      aux['No Load Price'] = hour['No Load Price'];

      /// add the non empty price/quantity pairs
      var pricesHour = <num?>[];
      var quantitiesHour = <num?>[];
      for (var i = 1; i <= 10; i++) {
        if (hour['Segment $i Price'] is! num) break;
        pricesHour.add(hour['Segment $i Price']);
        quantitiesHour.add(hour['Segment $i MW']);
      }
      aux['price'] = pricesHour;
      aux['quantity'] = quantitiesHour;
      row['hours'].add(aux);
    }
    validateDocument(row);
    return row;
  }

  @override
  Future insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data to insert');
      return Future.value(-1);
    }
    var groups = groupBy(data, (dynamic e) => e['date']);
    try {
      for (var date in groups.keys){
        for (var document in groups[date]!) {
          await dbConfig.coll.update({
            'date': date,
            'Masked Asset ID': document['Masked Asset ID'],
          }, document);
        }
        print('--->  Inserted $reportName for day $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx ' + e.toString());
      return 1;
    }
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return [];
    var dataByAssetId = groupBy(data, (dynamic row) => row['Masked Asset ID']);
    var out = dataByAssetId.keys
        .map((ptid) => converter(dataByAssetId[ptid]!))
        .toList();
    return out;
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res = await dbConfig.coll.findOne({'date': date.toString()});
    if (res == null || res.isEmpty) return false;
    return true;
  }

  /// Recreate the collection from scratch.
  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    var collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName)) {
      await dbConfig.coll.drop();
    }

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'date': 1,
          'Masked Asset ID': 1,
          'Masked Lead Participant ID': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.close();
  }

  Future<Map<String, String?>> lastDay() async {
    var pipeline = [];
    pipeline.add({
      '\$group': {
        '_id': 0,
        'lastDay': {'\$max': '\$date'}
      }
    });
    Map res = await dbConfig.coll.aggregate(pipeline);
    return {'lastDay': res['result'][0]['lastDay']};
  }

  /// return the last day of the fourth month before the current month.
  Date lastDayAvailable() {
    var m3 = Month.current().subtract(3);
    return Date.utc(m3.year, m3.month, 1).previous;
  }

  // Future<void> deleteDay(Date day) async {
  //   return await (dbConfig.coll.remove(mongo.where.eq('date', day.toString()))
  //       as FutureOr<void>);
  // }

  /// Check if this document is OK.  Throws otherwise.  May not catch all
  /// issues.
  void validateDocument(Map row) {
    if (row.containsKey('Unit Status') &&
        !_unitStates.contains(row['Unit Status'])) {
      throw StateError('Invalid unit state: ${row['Unit State']}.');
    }
  }
}
