library db.other.forward_marks;

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';

class ForwardMarksArchive {
  ComponentConfig dbConfig;

  /// Marks are inserted into the db for a given (curveId, asOfDate) tuple.
  /// Not all curves have marks updated every day.  Queries need to be
  /// smart to look at the last date before the requested asOfDate.
  ///
  ForwardMarksArchive({this.dbConfig}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'marks'
      ..collectionName = 'forward_marks';
  }

  Db get db => dbConfig.db;

  /// All data is for the same date, multiple curves.  Each element of the list
  /// is for one curveId.
  /// <p>One document format:
  /// {
  ///   'asOfDate': 'yyyy-mm-dd',
  ///   'curveId': 'iso:ISONE;ptid:4000',
  ///   'months': ['2019-01', '2019-02', ...],
  ///   '5x16': [89.10, 86.25, ...],
  ///   '2x16H': [...],
  ///   '7x8': [...],
  /// }
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    try {
      for (var document in data) {
        checkDocument(document);
        await dbConfig.coll.update({
          'asOfDate': document['asOfDate'],
          'curveId': document['curveId'],
        }, document, upsert: true);
        print(
            '--->  Inserted forward marks for ${document['curveId']} as of ${document['asOfDate']} successfully');
      }
      return Future.value(0);
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
  }

  /// Basic checks on the document structure.
  void checkDocument(Map<String,dynamic> document) {
    var keys = document.keys.toSet();
    var mustHaveKeys = <String>{'asOfDate', 'curveId', 'months'};
    if (!keys.containsAll(mustHaveKeys))
      throw ArgumentError('Document must contain asOfDate, curveId, months');

    // check that the months start from prompt month
    var month0 = Month.parse((document['asOfDate'] as String).substring(0,7));
    var month1 = Month.parse((document['months'] as List).first as String);
    var monthN = Month.parse((document['months'] as List).last as String);
    if (month0.next != month1)
      throw ArgumentError('Months must start with prompt month.');

    // check that month1 is after asOfDate
    var asOfDate = Date.parse(document['asOfDate']);
    if (!asOfDate.start.isBefore(month1.start))
      throw ArgumentError('asOfDate ');

    // check that the bucket names are valid
    var bucketKeys = keys.difference(mustHaveKeys);
    var validBuckets = {'7x24', '5x16', '2x16H', '7x8'};
    if (!bucketKeys.difference(validBuckets).isEmpty)
      throw ArgumentError('Invalid buckets $bucketKeys');

    // check that you mark until December
    if (monthN.month != 12)
      throw ArgumentError('Need to mark until December ${monthN.year}.');
  }

  setup() async {
    await db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'curveId': 1, 'asOfDate': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'asOfDate': 1});
    await dbConfig.db.close();
  }
}
