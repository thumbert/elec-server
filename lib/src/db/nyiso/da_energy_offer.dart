/// All data from ...
///   http://mis.nyiso.com/public/P-27list.htm
/// contains both the DAM and the HAM market (RT)

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/src/db/lib_nyiso_reports.dart';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';

class NyisoEnergyOfferArchive extends DailyNysioCsvReport {
  NyisoEnergyOfferArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'da_energy_offer');
    this.dbConfig = dbConfig;
    dir ??= '${super.dir}EnergyOffer/Raw/';
    this.dir = dir;
    reportName = 'NYISO DAM/HAM Energy Offers';
  }

  mongo.Db get db => dbConfig.db;
  static final log = Logger('NYISO Energy Offers');

  /// for DuckDb
  static final columns = <String, String>{
    'Masked Gen ID': 'INTEGER NOT NULL',
    'Date Time': 'TIMESTAMP_S',
    'Duration': 'TINYINT',
    'Market': "ENUM ('DAM', 'HAM')",
    'Expiration': 'TIMESTAMP_S',
    'Upper Oper Limit': 'FLOAT NOT NULL',
    'Emer Oper Limit': 'FLOAT NOT NULL',
    'Zero Start-Up Cost': "ENUM ('Y', 'N')",
    'On Dispatch': "ENUM ('Y', 'N')",
    'Bid SCHD Type Id': 'TINYINT NOT NULL',
    'Fixed Min Gen MW': 'FLOAT',
    'Fixed Min Gen Cost': 'FLOAT',
    'Bid Curve Format': "ENUM ('CURVE') NOT NULL",
    'Dispatch MW1': 'FLOAT',
    'Dispatch MW2': 'FLOAT',
    'Dispatch MW3': 'FLOAT',
    'Dispatch MW4': 'FLOAT',
    'Dispatch MW5': 'FLOAT',
    'Dispatch MW6': 'FLOAT',
    'Dispatch MW7': 'FLOAT',
    'Dispatch MW8': 'FLOAT',
    'Dispatch MW9': 'FLOAT',
    'Dispatch MW10': 'FLOAT',
    'Dispatch MW11': 'FLOAT',
    'Dispatch MW12': 'FLOAT',
    'Dispatch \$/MW1': 'FLOAT',
    'Dispatch \$/MW2': 'FLOAT',
    'Dispatch \$/MW3': 'FLOAT',
    'Dispatch \$/MW4': 'FLOAT',
    'Dispatch \$/MW5': 'FLOAT',
    'Dispatch \$/MW6': 'FLOAT',
    'Dispatch \$/MW7': 'FLOAT',
    'Dispatch \$/MW8': 'FLOAT',
    'Dispatch \$/MW9': 'FLOAT',
    'Dispatch \$/MW10': 'FLOAT',
    'Dispatch \$/MW11': 'FLOAT',
    'Dispatch \$/MW12': 'FLOAT',
    'Self Commit Timestamp1': 'TIMESTAMP_S',
    'Self Commit Timestamp2': 'TIMESTAMP_S',
    'Self Commit Timestamp3': 'TIMESTAMP_S',
    'Self Commit Timestamp4': 'TIMESTAMP_S',
    'Self Commit MW1': 'FLOAT',
    'Self Commit MW2': 'FLOAT',
    'Self Commit MW3': 'FLOAT',
    'Self Commit MW4': 'FLOAT',
    '10 Min Non-Synch MW': 'FLOAT',
    '10 Min Non-Synch Cost': 'FLOAT',
    '10 Min Spin MW': 'FLOAT',
    '10 Min Spin Cost': 'FLOAT',
    '30 Min Non-Synch MW': 'FLOAT',
    '30 Min Non-Synch Cost': 'FLOAT',
    '30 Min Spin MW': 'FLOAT',
    '30 Min Spin Cost': 'FLOAT',
    'Regulation MW': 'FLOAT',
    'Regulation Cost': 'FLOAT',
    'Masked Bidder ID': 'INTEGER NOT NULL',
    'Regulation Movement Cost': 'FLOAT',
  };

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
      print('xxxx ERROR xxxx $e');
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

  /// Get the ISO data and get it ready for DuckDb by removing inconsistencies.
  /// Check types.
  Map<String, dynamic> cleanRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      'Masked Gen ID': row['Masked Gen ID'] as int,
      'Date Time':
          NyisoReport.parseTimestamp2((row['Date Time'] as String).trim())
              .toIso8601String(),
      'Duration': row['Duration'] as int,
      'Market': (row['Market'] as String).trim(), // DAM or HAM
      'Expiration': row['Expiration'] == ' '
          ? null
          : NyisoReport.parseTimestamp2((row['Expiration'] as String).trim())
              .toIso8601String(),
      'Upper Oper Limit': row['Upper Oper Limit'] == ' '
          ? null
          : row['Upper Oper Limit'] as num,
      'Emer Oper Limit':
          row['Emer Oper Limit'] == ' ' ? null : row['Emer Oper Limit'] as num,
      'Zero Start-Up Cost': (row['Zero Start-Up Cost'] as String).trim(),
      'On Dispatch': (row['On Dispatch'] as String).trim(),
      'Bid SCHD Type Id': (row['Bid SCHD Type Id'] as num).toInt(),
      'Fixed Min Gen MW': row['Fixed Min Gen MW'] == ' '
          ? null
          : row['Fixed Min Gen MW'] as num,
      'Fixed Min Gen Cost': row['Fixed Min Gen Cost'] == ' '
          ? null
          : row['Fixed Min Gen Cost'] as num,
      'Bid Curve Format': (row['Bid Curve Format'] as String).trim(),
      'Dispatch MW1':
          row['Dispatch MW1'] == ' ' ? null : row['Dispatch MW1'] as num,
      'Dispatch MW2':
          row['Dispatch MW2'] == ' ' ? null : row['Dispatch MW2'] as num,
      'Dispatch MW3':
          row['Dispatch MW3'] == ' ' ? null : row['Dispatch MW3'] as num,
      'Dispatch MW4':
          row['Dispatch MW4'] == ' ' ? null : row['Dispatch MW4'] as num,
      'Dispatch MW5':
          row['Dispatch MW5'] == ' ' ? null : row['Dispatch MW5'] as num,
      'Dispatch MW6':
          row['Dispatch MW6'] == ' ' ? null : row['Dispatch MW6'] as num,
      'Dispatch MW7':
          row['Dispatch MW7'] == ' ' ? null : row['Dispatch MW7'] as num,
      'Dispatch MW8':
          row['Dispatch MW8'] == ' ' ? null : row['Dispatch MW8'] as num,
      'Dispatch MW9':
          row['Dispatch MW9'] == ' ' ? null : row['Dispatch MW9'] as num,
      'Dispatch MW10':
          row['Dispatch MW10'] == ' ' ? null : row['Dispatch MW10'] as num,
      'Dispatch MW11':
          row['Dispatch MW11'] == ' ' ? null : row['Dispatch MW11'] as num,
      'Dispatch MW12':
          row['Dispatch MW12'] == ' ' ? null : row['Dispatch MW12'] as num,
      'Dispatch \$/MW1':
          row['Dispatch \$/MW1'] == ' ' ? null : row['Dispatch \$/MW1'] as num,
      'Dispatch \$/MW2':
          row['Dispatch \$/MW2'] == ' ' ? null : row['Dispatch \$/MW2'] as num,
      'Dispatch \$/MW3':
          row['Dispatch \$/MW3'] == ' ' ? null : row['Dispatch \$/MW3'] as num,
      'Dispatch \$/MW4':
          row['Dispatch \$/MW4'] == ' ' ? null : row['Dispatch \$/MW4'] as num,
      'Dispatch \$/MW5':
          row['Dispatch \$/MW5'] == ' ' ? null : row['Dispatch \$/MW5'] as num,
      'Dispatch \$/MW6':
          row['Dispatch \$/MW6'] == ' ' ? null : row['Dispatch \$/MW6'] as num,
      'Dispatch \$/MW7':
          row['Dispatch \$/MW7'] == ' ' ? null : row['Dispatch \$/MW7'] as num,
      'Dispatch \$/MW8':
          row['Dispatch \$/MW8'] == ' ' ? null : row['Dispatch \$/MW8'] as num,
      'Dispatch \$/MW9':
          row['Dispatch \$/MW9'] == ' ' ? null : row['Dispatch \$/MW9'] as num,
      'Dispatch \$/MW10': row['Dispatch \$/MW10'] == ' '
          ? null
          : row['Dispatch \$/MW10'] as num,
      'Dispatch \$/MW11': row['Dispatch \$/MW11'] == ' '
          ? null
          : row['Dispatch \$/MW11'] as num,
      'Dispatch \$/MW12': row['Dispatch \$/MW12'] == ' '
          ? null
          : row['Dispatch \$/MW12'] as num,
      'Self Commit Timestamp1': row['Self Commit Timestamp1'] == ' '
          ? null
          : NyisoReport.parseTimestamp2(
                  (row['Self Commit Timestamp1'] as String).trim())
              .toIso8601String(),
      'Self Commit Timestamp2': row['Self Commit Timestamp2'] == ' '
          ? null
          : NyisoReport.parseTimestamp2(
                  (row['Self Commit Timestamp2'] as String).trim())
              .toIso8601String(),
      'Self Commit Timestamp3': row['Self Commit Timestamp3'] == ' '
          ? null
          : NyisoReport.parseTimestamp2(
                  (row['Self Commit Timestamp3'] as String).trim())
              .toIso8601String(),
      'Self Commit Timestamp4': row['Self Commit Timestamp4'] == ' '
          ? null
          : NyisoReport.parseTimestamp2(
                  (row['Self Commit Timestamp4'] as String).trim())
              .toIso8601String(),
      'Self Commit MW1':
          row['Self Commit MW1'] == ' ' ? null : row['Self Commit MW1'] as num,
      'Self Commit MW2':
          row['Self Commit MW2'] == ' ' ? null : row['Self Commit MW2'] as num,
      'Self Commit MW3':
          row['Self Commit MW3'] == ' ' ? null : row['Self Commit MW3'] as num,
      'Self Commit MW4':
          row['Self Commit MW4'] == ' ' ? null : row['Self Commit MW4'] as num,
      '10 Min Non-Synch MW': row['10 Min Non-Synch MW'] == ' '
          ? null
          : row['10 Min Non-Synch MW'] as num,
      '10 Min Non-Synch Cost': row['10 Min Non-Synch Cost'] == ' '
          ? null
          : row['10 Min Non-Synch Cost'] as num,
      '10 Min Spin MW':
          row['10 Min Spin MW'] == ' ' ? null : row['10 Min Spin MW'] as num,
      '10 Min Spin Cost': row['10 Min Spin Cost'] == ' '
          ? null
          : row['10 Min Spin Cost'] as num,
      '30 Min Non-Synch MW': row['30 Min Non-Synch MW'] == ' '
          ? null
          : row['30 Min Non-Synch MW'] as num,
      '30 Min Non-Synch Cost': row['30 Min Non-Synch Cost'] == ' '
          ? null
          : row['30 Min Non-Synch Cost'] as num,
      '30 Min Spin MW':
          row['30 Min Spin MW'] == ' ' ? null : row['30 Min Spin MW'] as num,
      '30 Min Spin Cost': row['30 Min Spin Cost'] == ' '
          ? null
          : row['30 Min Spin Cost'] as num,
      'Regulation MW':
          row['Regulation MW'] == ' ' ? null : row['Regulation MW'] as num,
      'Regulation Cost':
          row['Regulation Cost'] == ' ' ? null : row['Regulation Cost'] as num,
      'Masked Bidder ID': row['Masked Bidder ID'] as int,
      'Regulation Movement Cost': row['Regulation Movement Cost'] == ' '
          ? null
          : row['Regulation Movement Cost'] as num,
    };
  }

  /// Create a monthly file for DuckDb.  Cleanup a bit the ISO file.
  int makeGzFileForMonth(Month month) {
    var file = getZipFileForMonth(month);
    var rows = readReport(getReportDate(file), eol: '\n');

    var sb = StringBuffer();
    var converter = const ListToCsvConverter(convertNullTo: '');
    sb.writeln(converter.convert([columns.keys.toList()]));
    for (var row in rows) {
      sb.writeln(converter.convert([cleanRow(row).values.toList()]));
    }
    final fileOut =
        File('$dir../month/energy_offers_${month.toIso8601String()}.csv');
    fileOut.writeAsStringSync(sb.toString());

    // gzip it!
    var res = Process.runSync('gzip', ['-f', fileOut.path],
        workingDirectory: fileOut.parent.path);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(file.path)} has failed');
    }
    log.info('Gzipped file ${basename(file.path)}');

    return 0;
  }

  ///
  int updateDuckDb({required List<Month> months, required String pathDbFile}) {
    final con = Connection(pathDbFile);
    con.execute(r'''
CREATE TABLE IF NOT EXISTS da_offers (
    "Masked Gen ID" INTEGER NOT NULL,
    "Date Time" TIMESTAMPTZ,
    "Duration" TINYINT,
    "Market" ENUM ('DAM', 'HAM'),
    "Expiration" TIMESTAMPTZ,
    "Upper Oper Limit" FLOAT,
    "Emer Oper Limit" FLOAT,
    "Zero Start-Up Cost" ENUM ('Y', 'N'),
    "On Dispatch" ENUM ('Y', 'N'),
    "Bid SCHD Type Id" TINYINT NOT NULL,
    "Fixed Min Gen MW" FLOAT,
    "Fixed Min Gen Cost" FLOAT,
    "Bid Curve Format" ENUM ('CURVE') NOT NULL,
    "Dispatch MW1" FLOAT,
    "Dispatch MW2" FLOAT,
    "Dispatch MW3" FLOAT,
    "Dispatch MW4" FLOAT,
    "Dispatch MW5" FLOAT,
    "Dispatch MW6" FLOAT,
    "Dispatch MW7" FLOAT,
    "Dispatch MW8" FLOAT,
    "Dispatch MW9" FLOAT,
    "Dispatch MW10" FLOAT,
    "Dispatch MW11" FLOAT,
    "Dispatch MW12" FLOAT,
    "Dispatch $/MW1" FLOAT,
    "Dispatch $/MW2" FLOAT,
    "Dispatch $/MW3" FLOAT,
    "Dispatch $/MW4" FLOAT,
    "Dispatch $/MW5" FLOAT,
    "Dispatch $/MW6" FLOAT,
    "Dispatch $/MW7" FLOAT,
    "Dispatch $/MW8" FLOAT,
    "Dispatch $/MW9" FLOAT,
    "Dispatch $/MW10" FLOAT,
    "Dispatch $/MW11" FLOAT,
    "Dispatch $/MW12" FLOAT,
    "Self Commit Timestamp1" TIMESTAMP_S,
    "Self Commit Timestamp2" TIMESTAMP_S,
    "Self Commit Timestamp3" TIMESTAMP_S,
    "Self Commit Timestamp4" TIMESTAMP_S,
    "Self Commit MW1" FLOAT,
    "Self Commit MW2" FLOAT,
    "Self Commit MW3" FLOAT,
    "Self Commit MW4" FLOAT,
    "10 Min Non-Synch MW" FLOAT,
    "10 Min Non-Synch Cost" FLOAT,
    "10 Min Spin MW" FLOAT,
    "10 Min Spin Cost" FLOAT,
    "30 Min Non-Synch MW" FLOAT,
    "30 Min Non-Synch Cost" FLOAT,
    "30 Min Spin MW" FLOAT,
    "30 Min Spin Cost" FLOAT,
    "Regulation MW" FLOAT,
    "Regulation Cost" FLOAT,
    "Masked Bidder ID" INTEGER NOT NULL,
    "Regulation Movement Cost" FLOAT,
);  
  ''');
    for (var month in months) {
      log.info('Inserting month ${month.toIso8601String()}...');
      // remove the data if it's already there
      con.execute('''
DELETE FROM offers 
WHERE "Date Time" >= '${month.start.toIso8601String()}'
AND "Date Time" < '${month.end.toIso8601String()}';
      ''');
      // reinsert the data
      con.execute('''
INSERT INTO offers
FROM read_csv(
    '$dir../month/energy_offers_${month.toIso8601String()}.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
''');
    }
    con.close();

    return 0;
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
      File('$dir${yyyymmdd(month.startDate)}biddata_genbids_csv.zip');

  ///http://mis.nyiso.com/public/csv/biddata/20211001biddata_genbids_csv.zip
  @override
  String getUrlForMonth(Month month) =>
      'http://mis.nyiso.com/public/csv/biddata/${yyyymmdd(month.startDate)}biddata_genbids_csv.zip';

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
