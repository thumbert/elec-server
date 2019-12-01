library db.isoexpress.da_regulation_offer;

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:table/table.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaRegulationOfferArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;
  final location = getLocation('US/Eastern');

  DaRegulationOfferArchive({this.dbConfig, this.dir}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'isoexpress'
      ..collectionName = 'da_regulation_offer';

    dir ??= baseDir + 'PricingReports/DaRegulationOffer/Raw/';
  }
  var reportName = 'Historical Regulation Offer Data Report';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/hbregulationoffer?start=' +
          yyyymmdd(asOfDate);
  File getFilename(Date asOfDate) =>
      File(dir + 'hbregulationoffer_' + yyyymmdd(asOfDate) + '.csv');

  /// [rows] has the data for all the hours of the day for one asset
  Map<String, dynamic> converter(List<Map> rows) {
    var row = <String, dynamic>{};
    /// daily info
    row['date'] = formatDate(rows.first['Day']);
    row['Masked Lead Participant ID'] =
    rows.first['Masked Lead Participant ID'];
    row['Masked Asset ID'] = rows.first['Masked Asset ID'];
    row['hourBeginning'] = rows.map((e) {
      var utc = parseHourEndingStamp(e['Day'], e['Hour Ending']);
      return TZDateTime.fromMicrosecondsSinceEpoch(
          location, utc.microsecondsSinceEpoch)
          .toIso8601String();
    }).toList();

    row.addAll(rowsToColumns(rows, columns: [
      'Regulation Low Limit',
      'Regulation High Limit',
      'Regulation Status',   // AVAILABLE or UNAVAILABLE
      'Automatic Response Rate',
      'Regulation Service Offer Price',
      'Regulation Capacity Offer Price',
      'Regulation Inter-Temporal Opportunity Cost',
    ]));

    /// Calculate the Regulation Capacity according to the ISO formula
//    row['Regulation Capacity'] = rows.map((e) {
//      return min(5*e['Automatic Response Rate'],
//          0.5*(e['Regulation High Limit'] - e['Regulation Low Limit']));
//    }).toList();

    return row;
  }

  /// One report at a time.  Each element of the list is one Masked Asset ID.
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    var days = data.map((e) => e['date']).toSet();
    if (days.length > 1)
      throw ArgumentError('Only one date at a time allowed for insertion');
    try {
      await dbConfig.coll.remove({'date': data.first['date']});
      await dbConfig.coll.insertAll(data);
      print('---> Inserted $reportName for ${data.first['date']} successfully');
      return Future.value(0);
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
  }

  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String,dynamic>>[];
    var dataByAssetId = groupBy(data, (row) => row['Masked Asset ID']);
    var out = dataByAssetId.keys
        .map((ptid) => converter(dataByAssetId[ptid]))
        .toList();
    return out;
  }

  /// Recreate the collection from scratch.
  setupDb() async {
    await dbConfig.db.open();
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
}
