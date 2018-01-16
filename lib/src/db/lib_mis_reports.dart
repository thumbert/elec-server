library iso.isone.lib_mis_reports;

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:func/func.dart';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:intl/intl.dart';
import 'config.dart';

/// How to convert a set of rows in the csv report to a document in MongoDb.
abstract class DbDataConverter {
  List<Map> convert(List<Map> data);
}


abstract class MisReportArchive {
  String reportName;
  ComponentConfig dbConfig;

  /// A function to convert each row (or possibly a group of rows) of the
  /// report to a Map for insertion in a MongoDb document.
  Func1<List<Map>, Map> converter;

  /// Setup the database from scratch again, including the index
  Future<Null> setupDb();

  /// Bring the database up to date.
  Future<Null> updateDb();

  /// Load this file from disk and process it (add conversions, reformat, etc.)
  /// Make it ready for insertion in the database.
  List<Map> processFile(File file);

  /// Insert this data into the database.
  Future insertData(List<Map> data) async {
    return dbConfig.coll
        .insertAll(data)
        .then((_) => print('--->  Inserted successfully'))
        .catchError((e) => print('   ' + e.toString()));
  }
}




class MisReport {
  /// the location of where this report lives on the disk
  File file;

  /// Note that there can be several reports for the same report date
  /// because of resettlements.
  MisReport(this.file);

  DateFormat _fmt1 = new DateFormat('MM/DD/yyyy HH:mm:ss zzz');

  /// Parse the report date from the comments section.
  Future<Date> forDate() async {
    List<String> _comments = await comments();
    var regex = new RegExp(r'Report for: (.*)(")');
    var matches = regex.firstMatch(_comments[2]);
    var mmddyyyy = matches.group(1);
    return new Date(
        int.parse(mmddyyyy.substring(6, 10)),
        int.parse(mmddyyyy.substring(0, 2)),
        int.parse(mmddyyyy.substring(3, 5)));
  }
  
  /// Read the filename from the reports comments section.  This
  /// is the ISO filename, may be different from the filename of
  /// the report in local archive.
  Future<String> filename() async {
    List<String> _comments = await comments();
    var regex = new RegExp(r'Filename: (.*)(")');
    var matches = regex.firstMatch(_comments[1]);
    return matches.group(1);
  }

  /// Get the timestamp of the report as generated by the ISO.  For
  /// ISO Express reports, every time you download the report you will get
  /// a different timestamp although the filename is the same.  The usual
  /// MIS reports have the timestamp embedded in the filename as a GMT
  /// timestamp.
  Future<DateTime> timestamp() async {
    List<String> _comments = await comments();
    var regex = new RegExp(r'Report generated: (.*)(")');
    var matches = regex.firstMatch(_comments[3]);
    String timestamp = matches.group(1);
    return _fmt1.parse(timestamp.substring(0,20));
  }

  /// Read an MIS report and keep only the data rows, each row becoming a map,
  /// with keys taken from the header.
  /// If there are no data rows (empty report tab), return an empty List.
  List<Map> readTabAsMap({int tab: 0}) {
    List allData = _readReport(file, tab: tab);
    List columnNames = allData.firstWhere((List e) => e[0] == 'H');
    return allData
        .where((List e) => e[0] == 'D')
        .map((List e) => new Map.fromIterables(columnNames, e))
        .toList();
  }

  /// the rows in the report labeled 'C'.
  Future<List<String>> comments() async {
    return await file
        .openRead()
        .transform(UTF8.decoder)
        .transform(new LineSplitter())
        .takeWhile((String line) => line.startsWith('"C"'))
        .toList();
  }

  //toDb(List<Map>)

}

/// Read an MIS report and keep only the data rows, each row becoming a map,
/// with keys taken from the header.
/// If there are no data rows (empty report), return an empty List.
List<Map> readReportTabAsMap(File file, {int tab: 0}) {
  if (!file.existsSync())
    throw 'File ${file.path} doesn\'t exist.';
  List allData = _readReport(file, tab: tab);
  List columnNames = allData.firstWhere((List e) => e[0] == 'H');
  return allData
      .where((List e) => e[0] == 'D')
      .map((List e) => new Map.fromIterables(columnNames, e))
      .toList();
}

/// Read/process MIS reports.  Read all the report in memory, but
/// only parses the csv for the tab you are interested in.
/// Return each row of the [tab] as a List (all rows: C, H, D, T).
List<List> _readReport(File file, {int tab: 0}) {
  var converter = new CsvToListConverter();
  var lines = file.readAsLinesSync();
  if (!lines.last.startsWith('"T"'))
    throw new IncompleteReportException('Incomplete CSV file ${file.path}');

  int nHeaders = 0;
  return lines
      .where((e) {
        if (e[0] == 'H') ++nHeaders;
        if (nHeaders == 2 * tab || nHeaders == (2 * tab + 1))
          return true;
        else
          return false;
      })
      .map((String row) => converter.convert(row).first)
      .toList();
}


class IncompleteReportException implements Exception {
  String message;
  IncompleteReportException(this.message);
  String toString() => message;
}