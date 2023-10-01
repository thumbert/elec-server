library iso.isone.isoexpress;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:path/path.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import 'lib_mis_reports.dart' as mis;

var _env = Platform.environment;
String baseDir = '${_env['HOME'] ?? ''}/Downloads/Archive/IsoExpress/';
void setBaseDir(String dirName) => baseDir = dirName;

/// An generic ISO Express Report class.
abstract class IsoExpressReport {
  late String reportName;
  late ComponentConfig dbConfig;
  final Location location = getLocation('America/New_York');

  /// the location of this report on disk
  late String dir;

  /// A function to convert each row (or possibly a group of rows) of the
  /// report to a Map for insertion in a MongoDb document.
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) => rows.first;

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
  Future downloadUrl(
    String url,
    File fileout, {
    bool overwrite = true,
    String? username,
    String? password,
    String? acceptHeader,
    bool zipFile = false,
  }) async {
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
      if (acceptHeader != null) {
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      }
      var response = await request.close();
      if (response.statusCode == 200) {
        await response.pipe(fileout.openWrite());
      } else {
        print('Error downloading, status code: ${response.statusCode}');
      }
      if (zipFile) {
        var zipFilename =
            basename(fileout.path).replaceAll(RegExp('\\.csv\$'), '.zip');
        var res = Process.runSync('zip', [zipFilename, basename(fileout.path)],
            workingDirectory: dir);
        if (res.exitCode == 0) {
          fileout.deleteSync();
        }
      }
    }
  }

  /// Insert this data into the database.
  Future insertData(List<Map<String, dynamic>> data) async {
    return dbConfig.coll
        .insertAll(data)
        .then((_) => print('--->  Inserted successfully'))
        .catchError((e) => print('   $e'));
  }
}

/// An archive that gets daily updates.  Easy to update!
abstract class DailyIsoExpressReport extends IsoExpressReport {
  /// Get the url of this report for this date
  String getUrl(Date asOfDate);

  /// Get the filename of this report as saved on disk.  There is one ISO
  /// Express report per day.  Note that you can have multiple MIS reports
  /// per day.
  File getFilename(Date asOfDate);

  /// Download one day.  Check if the file has downloaded successfully.
  Future downloadDay(Date day) async {
    return await downloadUrl(getUrl(day), getFilename(day), overwrite: true);
  }

  /// Download a list of days from the website.
  Future downloadDays(List<Date> days) async {
    var aux = days.map((day) => downloadDay(day));
    return Future.wait(aux);
  }

  /// Read the report from the disk, and insert the data into the database.
  /// If the processing of the file throws an IncompleteReportException
  /// delete the file associated with this day.
  /// Remove the data associated with this [day] before reinserting.
  /// Returns 0 for success, 1 for error, null if there is no data to insert.
  ///
  Future<int> insertDay(Date day) async {
    var file = getFilename(day);
    List<Map<String, dynamic>> data;
    try {
      data = processFile(file);
      if (data.isEmpty) return Future.value(-1);
      await dbConfig.coll.remove({'date': day.toString()});
      return dbConfig.coll.insertAll(data).then((_) {
        print('--->  Inserted $reportName for day $day');
        return 0;
      }).catchError((e) {
        print('XXXX $e');
        return 1;
      });
    } on mis.IncompleteReportException {
      await file.delete();
      return Future.value(-1);
    }
  }
}

/// Format a date to the yyyymmdd format, e.g. 20170115.
String yyyymmdd(Date? date) => date.toString().replaceAll('-', '');
