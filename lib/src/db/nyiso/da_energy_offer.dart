library db.nyiso.da_energy_offer;

/// All data from ...
/// http://mis.nyiso.com/public/P-27list.htm
///

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/lib_nyiso_report.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/timezone.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';

class NyisoDaEnergyOfferArchive extends DailyNysioCsvReport {
  NyisoDaEnergyOfferArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'da_energy_offer');
    this.dbConfig = dbConfig;
    dir ??= super.dir + 'DaEnergyOffer/Raw/';
    this.dir = dir;
    reportName = 'NYISO DAM Energy Offers';
  }

  mongo.Db get db => dbConfig.db;

  /// Insert data into db
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data to insert');
      return Future.value(-1);
    }
    var groups = groupBy(data, (dynamic e) => e['date']);
    try {
      for (var date in groups.keys) {
        await dbConfig.coll.remove({'date': date});
        await dbConfig.coll.insertAll(groups[date]!);
        print('--->  Inserted $reportName for day $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx ' + e.toString());
      return 1;
    }
  }

  /// One [file] for the entire month for DAM and HAM markets.
  /// Return a list of documents in this form for DAM market only:
  /// ```
  /// {
  ///   'date': '2021-01-01',
  ///   'Masked Asset ID': 3636180,
  ///   'Masked Lead Participant ID': 37249750,
  ///   'hours': {
  ///     'Economic Maximum': <num>[...],
  ///     'Economic Minimum': <num>[...],
  ///     'Startup Cost': <num>[...],
  ///     'price': <List<num>>[...],
  ///     'quantity': <List<num>>[...],
  ///     'Self Commit MW': <List<num>>[],    // field may not exist if empty
  ///     '10 Min Spin MW': <num>[],    // field may not exist if empty
  ///     '10 Min Spin Cost': <num>[],  // field may not exist if empty
  ///     '30 Min Spin MW': <num>[],    // field may not exist if empty
  ///     '30 Min Spin Cost': <num>[],  // field may not exist if empty
  ///     'Regulation MW': <num>[],     // field may not exist if empty
  ///     'Regulation Cost': <num>[],   // field may not exist if empty
  ///     'Regulation Movement Cost': <num>[],  // field may not exist if empty
  ///   }
  /// }
  /// ```
  /// Note that the segment quantities returned are now incremental to the
  /// previous segment.  The original data has segment quantities as cumulative.
  ///
  ///
  @override
  List<Map<String, dynamic>> processFile(File file) {
    var out = <Map<String, dynamic>>[];

    var xs = readReport(getReportDate(file), eol: '\n');
    if (xs.isEmpty) return out;

    /// Group rows by (Masked Asset ID, date)
    /// Note that there are two markets: DAM and HAM.
    /// Only deal with DAM here.
    var groups = groupBy(xs.where((e) => e['Market'].trim() == 'DAM'), (Map e) {
      var dt = NyisoReport.parseTimestamp2((e['Date Time'] as String).trim());
      var date = dt.toString().substring(0, 10);
      return Tuple2(e['Masked Gen ID'] as int, date);
    });

    for (var group in groups.keys) {
      out.add(converter(groups[group]!));
    }

    return out;
  }

  /// Format for Mongo
  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = <String, dynamic>{};

    /// daily info
    row['date'] = NyisoReport.parseTimestamp2((rows.first['Date Time']).trim())
        .toString()
        .substring(0, 10);
    row['Masked Lead Participant ID'] = rows.first['Masked Bidder ID'];
    row['Masked Asset ID'] = rows.first['Masked Gen ID'];

    /// hourly info
    row['hours'] = [];
    for (var hour in rows) {
      var aux = <String, dynamic>{};
      aux['Economic Maximum'] = hour['Upper Oper Limit'];
      aux['Economic Minimum'] = hour['Fixed Min Gen MW'];
      aux['Startup Cost'] = hour['Fixed Min Gen Cost'];

      /// add the non empty price/quantity pairs
      var pricesHour = <num>[];
      var quantitiesHour = <num>[];
      for (var i = 1; i <= 12; i++) {
        if (hour['Dispatch MW$i'] is! num) break;
        pricesHour.add(hour['Dispatch \$/MW$i']);
        quantitiesHour.add(hour['Dispatch MW$i']);
      }
      aux['price'] = pricesHour;
      // convert quantities to incremental view (helps with processing later)
      var incrementalQ = List.from(quantitiesHour);
      for (var i = 1; i < quantitiesHour.length; i++) {
        incrementalQ[i] =
            (100 * (quantitiesHour[i] - quantitiesHour[i - 1])).round() / 100;
      }
      aux['quantity'] = incrementalQ;
      // Deal with self commit MW.  4 segments corresponding to each 15 min
      // interval within the hour.  May self-commit only for several hours
      // in the day.  I've seen that there is still a pq pair for the hour.
      // I assume the self commit takes precedence.
      var selfCommitMw = <num>[];
      for (var i = 1; i < 5; i++) {
        if (hour['Self Commit MW$i'] is! num) break;
        selfCommitMw.add(hour['Self Commit MW$i']);
      }
      if (selfCommitMw.isNotEmpty) {
        aux['Self Commit MW'] = selfCommitMw;
      }
      if (hour['10 Min Spin Cost'] is num) {
        aux['10 Min Spin Cost'] = hour['10 Min Spin Cost'];
      }
      if (hour['10 Min Spin MW'] is num) {
        aux['10 Min Spin MW'] = hour['10 Min Spin MW'];
      }
      if (hour['30 Min Spin Cost'] is num) {
        aux['30 Min Spin Cost'] = hour['30 Min Spin Cost'];
      }
      if (hour['30 Min Spin MW'] is num) {
        aux['30 Min Spin MW'] = hour['30 Min Spin MW'];
      }
      if (hour['Regulation MW'] is num) {
        aux['Regulation MW'] = hour['Regulation MW'];
      }
      if (hour['Regulation Cost'] is num) {
        aux['Regulation Cost'] = hour['Regulation Cost'];
      }
      if (hour['Regulation Movement Cost'] is num) {
        aux['Regulation Movement Cost'] = hour['Regulation Movement Cost'];
      }

      row['hours'].add(aux);
    }
    return row;
  }

  /// Recreate the collection from scratch.
  @override
  Future<void> setupDb() async {
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

  @override
  Date getReportDate(File file) {
    var yyyymmdd = basename(file.path).substring(0, 8);
    return Date.utc(
        int.parse(yyyymmdd.substring(0, 4)),
        int.parse(yyyymmdd.substring(4, 6)),
        int.parse(yyyymmdd.substring(6, 8)));
  }

  @override
  File getZipFileForMonth(Month month) =>
      File(dir + yyyymmdd(month.startDate) + 'biddata_genbids_csv.zip');

  ///http://mis.nyiso.com/public/csv/biddata/20211001biddata_genbids_csv.zip
  @override
  String getUrlForMonth(Month month) =>
      'http://mis.nyiso.com/public/csv/biddata/' +
      yyyymmdd(month.startDate) +
      'biddata_genbids_csv.zip';

  @override
  File getCsvFile(Date asOfDate) {
    var month = Month.utc(asOfDate.year, asOfDate.month);
    var fileName = getZipFileForMonth(month).path;
    fileName = fileName.replaceAll('_csv.zip', '.csv');
    return File(fileName);
  }

  @override
  String getUrl(Date asOfDate) {
    throw StateError('Individual day url does not exist for this report');
  }
}

// /// Check if this document is OK.  Throws otherwise.  May not catch all
// /// issues.
// void validateDocument(Map row) {
//   if (row.containsKey('Unit Status') &&
//       !_unitStates.contains(row['Unit Status'])) {
//     throw StateError('Invalid unit state: ${row['Unit State']}.');
//   }
// }
