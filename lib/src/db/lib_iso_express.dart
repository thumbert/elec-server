library iso.isone.isoexpress;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:path/path.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import 'lib_mis_reports.dart' as mis;

var _env = Platform.environment;
String baseDir = (_env['HOME'] ?? '') + '/Downloads/Archive/IsoExpress/';
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
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows);

  /// Setup the database from scratch again, including the index
  Future<Null> setupDb();

  /// Bring the database up to date.
  /// Future<Null> updateDb();

  /// Load this file from disk and process it (add conversions, reformat, etc.)
  /// Make it ready for insertion in the database.
  List<Map<String, dynamic>> processFile(File file);

  /// Download this url to a file.
  Future downloadUrl(String? url, File fileout, {bool overwrite = true}) async {
    if (fileout.existsSync() && !overwrite) {
      print('File ${fileout.path} was already downloaded.  Skipping.');
      return Future.value(1);
    } else {
      if (!Directory(dirname(fileout.path)).existsSync()) {
        Directory(dirname(fileout.path)).createSync(recursive: true);
        print('Created directory ${dirname(fileout.path)}');
      }
      var client = HttpClient();
      var request = await client.getUrl(Uri.parse(url!));
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

/// An archive that gets daily updates.  Easy to update!
abstract class DailyIsoExpressReport extends IsoExpressReport {
  /// Get the url of this report for this date
  String getUrl(Date? asOfDate);

  /// Get the filename of this report as saved on disk.  There is one ISO
  /// Express report per day.  Note that you can have multiple MIS reports
  /// per day.
  File getFilename(Date? asOfDate);

  /// Return the last day inserted in the db.
  /// Future<Map<String, String>> lastDay();

  /// What is the last day available from the ISO website.  For example,
  /// NCPC reports are 4-7 days later.  Offer data is 4 months later.
  /// If data is not available, the reports will be empty, so no harm done.
  //Date lastDayAvailable();

  /// Delete one day from the archive.
  //Future<Null> deleteDay(Date day);

  /// Download one day.  Check if the file has downloaded successfully.
  Future downloadDay(Date? day) async {
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
    var data;
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
}

/// Format a date to the yyyymmdd format, e.g. 20170115.
String yyyymmdd(Date? date) => date.toString().replaceAll('-', '');
