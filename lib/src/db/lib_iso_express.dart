library iso.isone.isoexpress;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:path/path.dart';
import 'package:elec_server/src/db/config.dart';
import 'lib_mis_reports.dart' as mis;

Map env = Platform.environment;
String baseDir = env['HOME'] + '/Downloads/Archive/IsoExpress/';
void setBaseDir(String dirName) => baseDir = dirName;

/// An generic ISO Express Report class.
abstract class IsoExpressReport {
  String reportName;
  ComponentConfig dbConfig;

  /// A function to convert each row (or possibly a group of rows) of the
  /// report to a Map for insertion in a MongoDb document.
  Map<String,dynamic> converter(List<Map<String,dynamic>> rows);

  /// Setup the database from scratch again, including the index
  Future<Null> setupDb();

  /// Bring the database up to date.
  /// Future<Null> updateDb();

  /// Load this file from disk and process it (add conversions, reformat, etc.)
  /// Make it ready for insertion in the database.
  List<Map<String, dynamic>> processFile(File file);

  /// Download this url to a file.
  Future downloadUrl(String url, File fileout, {bool override: true}) async {
    if (fileout.existsSync() && !override) {
      print('File ${fileout.path} was already downloaded.  Skipping.');
      return new Future.value(1);
    } else {
      if (!new Directory(dirname(fileout.path)).existsSync()) {
        new Directory(dirname(fileout.path)).createSync(recursive: true);
        print('Created directory ${dirname(fileout.path)}');
      }
      HttpClient client = new HttpClient();
      HttpClientRequest request = await client.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
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
  /// the location of this report on disk
  String dir;

  /// Get the url of this report for this date
  String getUrl(Date asOfDate);

  /// Get the filename of this report as saved on disk.  There is one ISO
  /// Express report per day.  Note that you can have multiple MIS reports
  /// per day.
  File getFilename(Date asOfDate);

  /// Return the last day inserted in the db.
  /// Future<Map<String, String>> lastDay();

  /// What is the last day available from the ISO website.  For example,
  /// NCPC reports are 4-7 days later.  Offer data is 4 months later.
  /// If data is not available, the reports will be empty, so no harm done.
  //Date lastDayAvailable();

  /// Check if this date is in the archive already.  Return [true] if it is.
  Future<bool> hasDay(Date day);

  /// Delete one day from the archive.
  Future<Null> deleteDay(Date day);

  /// Download one day.  Check if the file has downloaded successfully.
  /// If [override] is true, re-download the day.
  Future downloadDay(Date day, {bool override: true}) async {
    return await downloadUrl(getUrl(day), getFilename(day), override: override);
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
  /// Returns 0 for success.
  Future insertDay(Date day) async {
    File file = getFilename(day);
    var data;
    try {
      data = processFile(file);
      if (data.isEmpty) return new Future.value(null);
    } on mis.IncompleteReportException {
      file.delete();
      return new Future.value(null);
    }
    await dbConfig.coll.remove({'date': day.toString()});
    return dbConfig.coll.insertAll(data).then((_) {
      print('--->  Inserted ${reportName} for day ${day}');
      return 0;
    }).catchError((e) => print('  ' + e.toString()));
  }
}

/// Format a date to the yyyymmdd format, e.g. 20170115.
String yyyymmdd(Date date) => date.toString().replaceAll('-', '');
