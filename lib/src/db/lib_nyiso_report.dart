library db.lib_nysio_report;

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
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
  static final Location location = getLocation('America/New_York');

  /// the location of this report on disk
  String dir =
      (Platform.environment['HOME'] ?? '') + '/Downloads/Archive/Nyiso/';

  /// Parse NYISO timestamp as it appears in the Csv reports.
  /// Possible inputs (for example):
  ///   '01/01/2020 00:00', 'EST'
  ///   '03/08/2020 01:00', 'EST'  // spring forward next
  ///   '03/08/2020 03:00', 'EDT'
  ///   '11/01/2020 01:00', 'EDT'  // fall back next
  ///   '11/01/2020 01:00', 'EST'
  ///
  /// Return a datetime in UTC.  See also [parseHourEndingStamp] from
  /// src/utils/iso_timestamp.dart for the corresponding ISONE function.
  ///
  static TZDateTime parseTimestamp(String timeStamp, String timeZone) {
    String tz;
    if (timeZone == 'EST') {
      tz = '-0500';
    } else if (timeZone == 'EDT') {
      tz = '-0400';
    } else {
      throw StateError('Unsupported timezone $timeZone');
    }
    var yyyy = timeStamp.substring(6, 10);
    var mm = timeStamp.substring(0, 2);
    var dd = timeStamp.substring(3, 5);
    var hh = timeStamp.substring(11, 13);
    var minutes = timeStamp.substring(14, 16);

    var res = TZDateTime.parse(location, '$yyyy-$mm-${dd}T$hh:$minutes:00$tz');
    return res.toUtc();
  }

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

  /// Get the file of this report as saved on disk.  There is one ISO
  /// Express report per day.  Note that you can have multiple MIS reports
  /// per day.
  File getFile(Date asOfDate);

  /// Get the date associated with this file.
  Date getReportDate(File file);

  /// Download one day.  Check if the file has downloaded successfully.
  /// NYISO only keeps the most recent 10 days, so you may have to download
  /// the entire month.
  Future downloadDay(Date day, {bool overwrite = true}) async {
    return await downloadUrl(getUrl(day), getFile(day), overwrite: overwrite);
  }

  /// All month reports are zipped
  Future downloadMonth(Month month, {bool overwrite = true}) async {
    var asOfDate = month.startDate;
    var url = getUrl(asOfDate).replaceAll('.csv', '_csv') + '.zip';
    var filename = File(getFile(asOfDate).path + '.zip');
    return await downloadUrl(url, filename, overwrite: overwrite);
  }

  /// Read the report from the disk, and insert the data into the database.
  /// If the processing of the file throws an IncompleteReportException
  /// delete the file associated with this day.
  /// Remove the data associated with this [day] before reinserting.
  /// Returns 0 for success, 1 for error, null if there is no data to insert.
  ///
  Future<int> insertDay(Date day) async {
    var file = getFile(day);
    List<Map<String, dynamic>> data;
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

  /// Read the report associated with the data, doing no processing.
  /// Return tabular data.  To get the data in the format needed for the
  /// database see the [processFile(file)] method.
  List<Map<String, dynamic>> readReport(Date date) {
    var file = getFile(date);
    var out = <Map<String, dynamic>>[];
    var converter = CsvToListConverter();

    var zipFile =
        File(getFile(Date.utc(date.year, date.month, 1)).path + '.zip');
    final bytes = zipFile.readAsBytesSync();
    var zipArchive = ZipDecoder().decodeBytes(bytes);

    var _file = zipArchive.findFile(basename(file.path));
    if (_file != null) {
      var _lines = _file.content as List<int>;
      var csv = utf8.decoder.convert(_lines);
      // print(csv);
      var xs = converter.convert(csv);
      if (xs.isNotEmpty) {
        var header = xs.removeAt(0).cast<String>();
        for (var x in xs) {
          out.add(Map.fromIterables(header, x));
        }
      }
    }

    return out;
  }
}

/// Format a date to the yyyymmdd format, e.g. 20170115.
String yyyymmdd(Date date) => date.toString().replaceAll('-', '');
