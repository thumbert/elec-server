library lib.db.cme.cme_energy_settlements;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:timezone/timezone.dart';

class CmeSettlementsEnergyArchive {
  CmeSettlementsEnergyArchive({ComponentConfig? dbConfig, String? dir}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1',
            dbName: 'cme',
            collectionName: 'settlements');
    this.dir = dir ?? '$baseDir../Cme/Settlements/Energy/Raw/';
    if (!Directory(this.dir).existsSync()) {
      Directory(this.dir).createSync(recursive: true);
    }
  }

  final String reportName =
      'CME daily settlement report for energy futures & options';
  late final String dir;
  late final ComponentConfig dbConfig;
  final log = Logger('CME energy settlements');


  final curveMapping = <String, String>{
    'OIL_WTI_CME': 'CL Light Sweet Crude Oil Futures',
    'OIL_HO_CME': 'HO NY Harbor ULSD Futures',
    'NG_HENRY_HUB_CME': 'NG Henry Hub Natural Gas Futures',
    'NG_TTF_USD_CME': 'TTE Dutch TTF Natural Gas (USD/MMBtu) (ICIS Heren) Front Month Futures',
  };

  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      log.info('--->  No data to insert in cme/settlements_energy');
      return Future.value(0);
    }
    var groups = groupBy(data, (Map e) => e['fromDate']);
    try {
      for (var date in groups.keys) {
        await dbConfig.coll.remove({'fromDate': date});
        await dbConfig.coll.insertAll(groups[date]!);
        log.info('--->  Inserted CME Energy Settlement prices for day $date');
      }
      return 0;
    } catch (e) {
      log.severe('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  /// The file may actually not exist because the date is not a trading day
  /// or it was not downloaded at the time.  If file doesn't exist, return
  /// [null].
  File getFilename(Date asOfDate) {
    return File('${dir}energy_settlement_${asOfDate.toString()}.txt');
  }

  ///
  Future<int> downloadDataToFile() async {
    var res = await get(
        Uri.parse('https://www.cmegroup.com/ftp/pub/settle/stlnymex_v2'));
    if (res.statusCode == 200) {
      var data = res.body;
      var rows = data.split('\n');
      var date = getReportDate(rows.first);
      if (date == null) {
        return Future.value(-1);
      }
      var fileOut = File('$dir/energy_settlement_${date.toString()}.txt');
      fileOut.writeAsStringSync(data);
      return Future.value(0);
    }
    return Future.value(-1);
  }

  Date? getReportDate(String row0) {
    var regex = RegExp(r'(\d{2}/\d{2}/\d{4})');
    if (regex.hasMatch(row0)) {
      var matches = regex.allMatches(row0);
      var match = matches.elementAt(0);
      var date = Date.parse(match.group(0)!, location: UTC);
      return date;
    }
    return null;
  }

  /// Return a list of documents.  Each document is in this form:
  /// ```dart
  /// {
  ///   'fromDate': '2023-04-28',
  ///   'curveId': 'PRC_NG_HENRY',
  ///   'terms': ['2023-06', ... '2035-12'],
  ///   'values': <num>[...],
  /// }
  /// ```
  List<Map<String, dynamic>> processFile(File file) {
    var xs = file.readAsLinesSync();
    var out = <Map<String, dynamic>>[];
    for (var entry in curveMapping.entries) {
      log.info('Working on ${entry.value}');
      var indStart = xs.indexWhere((e) => e.startsWith(entry.value)) + 1;
      if (indStart == -1) {
        throw StateError('Can\'t find ${entry.value} in the file!');
      }
      var indEnd = indStart;
      while (xs[indEnd][73] != ' ') {
        indEnd += 1;
        if (xs[indEnd].length < 69) {
          break;
        }
      }
      var values = extractPriceColumn(xs.sublist(indStart, indEnd));
      if (values.isEmpty) {
        throw StateError('Failed extracting the prices for ${entry.value}');
      }
      out.add({
        'fromDate': getReportDate(xs.first).toString(),
        'curveId': entry.key,
        'terms': xs
            .sublist(indStart, indEnd)
            .map((e) => e.substring(0, 5))
            .map((e) => Month.parse(e, location: UTC).toIso8601String())
            .toList(),
        'values': values,
      });
    }
    return out;
  }

  /// Rows are fixed column.  For example
  ///
  /// NG Henry Hub Natural Gas Futures
  /// JUN23          2.35800      2.54600B     2.28500      2.39800      2.41000      +.05500      176420        2.35500      105218      200594
  /// JUL23          2.53800      2.70000      2.48400      2.56900A     2.57800      +.03000       81153        2.54800       54019      266198
  /// AUG23          2.61200      2.75700      2.56000      2.63500A     2.64500      +.02800       34809        2.61700       18297       69229
  /// SEP23          2.59700      2.74300      2.54400A     2.61900B     2.62600      +.02600       28655        2.60000       14817      124910
  /// ...
  /// The 6th column is the settlement price for the day (sometimes there are no 6 columns.)
  ///
  List<num> extractPriceColumn(List<String> rows) {
    var xs = rows
        .map((e) => e.substring(67, 75))
        .map((e) => num.tryParse(e))
        .toList();
    if (xs.any((e) => e == null)) {
      throw StateError('Parsing failed for $xs');
    }
    return xs.cast<num>();
  }

  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'fromDate': 1,
          'curveId': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'fromDate': 1});
    await dbConfig.db.close();
  }
}
