library db.archive;

import 'dart:async';
import 'package:date/date.dart';

/// An abstract class for a daily ingestion into mongo.
abstract class DailyArchive {

  /// get the daily data from a web source, always save it for reference
  oneDayDownload(Date date);

  /// read the data from local archive and format it for insertion into mongo
  List<Map> oneDayRead(Date date);

  /// insert into mongo, one day of data
  oneDayMongoInsert(Date date);

  /// get the last day inserted in the archive
  Future<Date> lastDayInserted();

  /// create the collection, insert one day, create the right index
  setup();

  /// maintain the Db
  updateDb(Date start, Date end);
}

