library db.lib_nysio_report;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:path/path.dart';
import 'package:csv/csv.dart';
import 'package:archive/archive.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import 'lib_mis_reports.dart' as mis;

/// A generic NYISO Report class.
abstract class NyisoReport {
  late String reportName;
  late ComponentConfig dbConfig;
  final Location location = getLocation('America/New_York');

  /// the location of this report on disk
  String dir = (Platform.environment['HOME'] ?? '') + '/Downloads/Archive/Nyiso/';

  /// A function to convert each row (or possibly a group of rows) of the
  /// report to a Map for insertion in a MongoDb document.
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows);

  /// Setup the database from scratch again, including the index
  Future<void> setupDb();

  /// Bring the database up to date.
  /// Future<Null> updateDb();

  /// Load this file from disk and process it (add conversions, reformat, etc.)
  /// Make it ready for insertion in the database.
  List<Map<String, dynamic>> processFile(File file);

  /// Download this url to a file.
  /// Basic authentication is supported.
  /// [acceptHeader] can be set to 'application/json' if you need json output.
  Future downloadUrl(String url, File fileout,
      {bool overwrite = true,
        String? username,
        String? password,
        String? acceptHeader}) async {
    if (fileout.existsSync() && !overwrite) {
      print('File ${fileout.path} was already downloaded.  Skipping.');
      return Future.value(1);
    } else {
      if (!Directory(dirname(fileout.path)).existsSync()) {
        Directory(dirname(fileout.path)).createSync(recursive: true);
        print('Created directory ${dirname(fileout.path)}');
      }
      var client = HttpClient()
        ..userAgent =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3419.0 Safari/537.36'
        ..badCertificateCallback = (cert, host, port) => true;
      if (username != null && password != null) {
        client.addCredentials(
            Uri.parse(url), '', HttpClientBasicCredentials(username, password));
      }
      var request = await client.getUrl(Uri.parse(url));
      // if (acceptHeader != null) {
      //   request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      // }
      var response = await request.close();
      await response.pipe(fileout.openWrite());
    }
  }

  /// Insert this data into the database.
  Future insertData(List<Map<String, dynamic>> data) async {
    return dbConfig.coll
        .insertAll(data)
        .then((_) => print('--->  Inserted successfully'))
        .catchError((e) => print('   ' + e.toString()));
  }
}

/// An archive that gets daily updates.
abstract class DailyNysioCsvReport extends NyisoReport {
  /// Get the url of this report for this date
  String getUrl(Date asOfDate);

  /// Get the filename of this report as saved on disk.  There is one ISO
  /// Express report per day.  Note that you can have multiple MIS reports
  /// per day.
  File getFilename(Date asOfDate);

  /// Download one day.  Check if the file has downloaded successfully.
  /// NYISO only keeps the most recent 10 days
  Future downloadDay(Date day, {bool overwrite = true}) async {
    return await downloadUrl(getUrl(day), getFilename(day), overwrite: overwrite);
  }

  /// All month reports are zipped
  Future downloadMonth(Month month, {bool overwrite = true}) async {
    var asOfDate = month.startDate;
    var url = getUrl(asOfDate).replaceAll('.csv', '_csv') + '.zip';
    var filename = File(getFilename(asOfDate).path + '.zip');
    return await downloadUrl(url, filename, overwrite: overwrite);
  }

  /// Read the report from the disk, and insert the data into the database.
  /// If the processing of the file throws an IncompleteReportException
  /// delete the file associated with this day.
  /// Remove the data associated with this [day] before reinserting.
  /// Returns 0 for success, 1 for error, null if there is no data to insert.
  ///
  Future<int> insertDay(Date day) async {
    var file = getFilename(day);
    List<Map<String,dynamic>> data;
    try {
      data = processFile(file);
      if (data.isEmpty) return Future.value(-1);
      await dbConfig.coll.remove({'date': day.toString()});
      return dbConfig.coll.insertAll(data).then((_) {
        print('--->  Inserted $reportName for day $day');
        return 0;
      }).catchError((e) {
        print('XXXX ' + e.toString());
        return 1;
      });
    } on mis.IncompleteReportException {
      await file.delete();
      return Future.value(-1);
    }
  }

  List<Map<String,dynamic>> readReport(Date date) {
   var file = getFilename(date);

    /// all the lines in the report
    var _lines = file.readAsLinesSync();

    var converter = CsvToListConverter();
    if (_lines.isEmpty ||
        !(_lines.last.startsWith('"T"') || _lines.last.startsWith('T'))) {
      throw mis.IncompleteReportException('Incomplete CSV file ${file.path}');
    }

    // var nHeaders = -1;
    // return _lines
    //     .where((e) {
    //   if (e[0] == 'H' || e.startsWith('"H"')) nHeaders++;
    //   if (nHeaders == 2 * tab || nHeaders == (2 * tab + 1)) {
    //     return true;
    //   } else {
    //     return false;
    //   }
    // })
    //     .map((String row) => converter.convert(row).first)
    //     .toList();
  }
}


/// Format a date to the yyyymmdd format, e.g. 20170115.
String yyyymmdd(Date date) => date.toString().replaceAll('-', '');
