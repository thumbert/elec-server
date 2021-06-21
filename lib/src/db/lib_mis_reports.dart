library iso.isone.lib_mis_reports;

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';
import 'config.dart';

///
List<Map<String, dynamic>> expandDocument(List<Map<String, dynamic>> xs,
    Set<String> scalarKeys, Set<String> vectorKeys) {
  var out = <Map<String, dynamic>>[];
  for (var x in xs) {
    var n = (x[vectorKeys.first] as List).length;
    for (var i = 0; i < n; i++) {
      var one = <String, dynamic>{};
      for (var scalar in scalarKeys) {
        one[scalar] = x[scalar];
      }
      for (var column in vectorKeys) {
        one[column] = x[column][i];
      }
      out.add(one);
    }
  }
  return out;
}

/// How to convert a set of rows in the csv report to a document in MongoDb.
abstract class DbDataConverter {
  List<Map> convert(List<Map> data);
}

abstract class MisReportArchive {
  late String reportName;
  late ComponentConfig dbConfig;
  final Location location = getLocation('America/New_York');

  /// A function to convert each row (or possibly a group of rows) of the
  /// report to a Map for insertion in a MongoDb document.
  Map<String, dynamic> Function(List<Map<String, dynamic>>)? converter;

  /// Setup the database from scratch again, including the index
  Future<Null> setupDb();

  /// Load this file from disk and process it (add conversions, reformat, etc.)
  /// Make it ready for insertion in the database.
  /// Each tab is one element of the returned Map.  The key of the Map is the tab
  /// number.
  Map<int, List<Map<String, dynamic>>> processFile(File file);

  /// Insert this data into the database.  Likely to be overwritten in the implementation.
  Future<int> insertTabData(List<Map<String, dynamic>> data,
      {int tab = 0}) async {
    if (data.isEmpty) return Future.value(-1);
    await dbConfig.coll
        .insertAll(data)
        .then((_) => print('--->  Inserted successfully'))
        .catchError((e) {
      print('   ' + e.toString());
      throw e;
    });
    return 0;
  }
}

class MisReport {
  /// the location of where this report lives on the disk
  final File file;

  /// Add labels to each data row.  Typical labels are something like
  ///
  ///```dart
  ///     var labels = <String,dynamic>{
  ///      'account': account,
  ///      'tab': 0,
  ///      'date': reportDate.toString(),
  ///      'version': version,
  ///    };
  ///```
  ///And usually the removed columns are ['H']
  static List<Map<String, dynamic>> addLabels(
      Iterable<Map<String, dynamic>> rows,
      Map<String, dynamic> labels,
      List<String> removeColumns) {
    return rows.map((e) {
      for (var column in removeColumns) {
        e.remove(column);
      }
      var out = <String, dynamic>{
        ...labels,
        ...e,
      };
      return out;
    }).toList();
  }

  /// all the lines in the report
  List<String>? _lines;
  CsvToListConverter? _converter;

  /// Note that there can be several reports for the same report date
  /// because of resettlements.
  MisReport(this.file);

  /// Get the account number from the filename.
  String accountNumber() {
    var split = basename(file.path).split('_');
    return split.elementAt(split.length - 3);
  }

  /// Get the name of the company from the report.
  Future<String?> companyName() async {
    var _comments = await comments();
    _converter ??= CsvToListConverter();
    var aux = _converter!.convert(_comments[2])[0];
    return aux[1];
  }

  /// Get the report date (operating day) from the filename
  Date forDate() {
    var split = basename(file.path).split('_');
    var date = split.elementAt(split.length - 2).substring(0, 8);
    return Date.parse(date);
  }

  /// Read the filename from the reports comments section.  This
  /// is the ISO filename, may be different from the filename of
  /// the report in local archive.  Return an UTC DateTime.
  DateTime timestamp() {
    var name = file.path.toUpperCase();
    var ind = name.lastIndexOf('_');
    var dt = name.substring(ind + 1);
    return DateTime.utc(
        int.parse(dt.substring(0, 4)), // year
        int.parse(dt.substring(4, 6)), // month
        int.parse(dt.substring(6, 8)), // day
        int.parse(dt.substring(8, 10)), // hour
        int.parse(dt.substring(10, 12)), // minute
        int.parse(dt.substring(12, 14)) // second
        );
  }

  Future<String?> filename() async {
    var _comments = await comments();
    var regex = RegExp(r'Filename: (.*)(")');
    var matches = regex.firstMatch(_comments[1])!;
    return matches.group(1);
  }

  /// Read an MIS report and keep only the data rows, each row becoming a map,
  /// with keys taken from the header.
  /// If there are no data rows (empty report tab), return an empty List.
  List<Map<String, dynamic>> readTabAsMap({int tab = 0}) {
    var allData = _readReport(tab: tab);
    var columnNames =
        allData.firstWhere((List e) => e[0] == 'H').cast<String>();
    return allData
        .where((List e) => e[0] == 'D')
        .map((List e) => Map.fromIterables(columnNames, e))
        .toList();
  }

  /// the rows in the report labeled 'C'.
  Future<List<String>> comments() async {
    return await file
        .openRead()
        .transform(Utf8Decoder())
        .transform(LineSplitter())
        .takeWhile((String line) => line.startsWith('"C"'))
        .toList();
  }

  /// Read/process MIS reports.  Read all the report in memory, but
  /// only parses the csv for the tab you are interested in.
  /// Return each row of the [tab] as a List (all rows in the report: C, H, D, T).
  /// Sometimes the ISO doesn't quote the report.  Really frustrating!
  /// [tab] the tab number to parse.  If the report changes and the tab
  /// doesn't exist return an empty list.
  List<List> _readReport({int tab = 0}) {
    var converter = CsvToListConverter();
    _lines ??= file.readAsLinesSync();
    if (_lines!.isEmpty ||
        !(_lines!.last.startsWith('"T"') || _lines!.last.startsWith('T'))) {
      throw IncompleteReportException('Incomplete CSV file ${file.path}');
    }

    var nHeaders = -1;
    return _lines!
        .where((e) {
          if (e[0] == 'H' || e.startsWith('"H"')) nHeaders++;
          if (nHeaders == 2 * tab || nHeaders == (2 * tab + 1)) {
            return true;
          } else {
            return false;
          }
        })
        .map((String row) => converter.convert(row).first)
        .toList();
  }
}

/// Read an MIS report and keep only the data rows, each row becoming a map,
/// with keys taken from the header.
/// If there are no data rows (empty report), return an empty List.
List<Map<String, dynamic>> readReportTabAsMap(File file, {int tab = 0}) {
  if (!file.existsSync()) throw 'File ${file.path} doesn\'t exist.';
  var allData = MisReport(file)._readReport(tab: tab);
  if (allData.isEmpty) return [];
  var columnNames = allData.firstWhere((List e) => e[0] == 'H').cast<String>();
  return allData
      .where((List e) => e[0] == 'D')
      .map((List e) => Map.fromIterables(columnNames, e))
      .toList();
}

/// Colnames in MIS reports sometimes have unnecessary parantheses.
/// For example: 'Internal Bilateral For Load (F)'.  Remove them.
String removeParanthesesEnd(String x) {
  var ind = x.indexOf(RegExp('\\(.*\\)'));
  if (ind != -1) {
    x = x.substring(0, ind);
  }
  return x.trim();
}

class IncompleteReportException implements Exception {
  String message;
  IncompleteReportException(this.message);
  @override
  String toString() => message;
}
