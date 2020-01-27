library db.marks.forward_marks;

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';
import 'package:intl/intl.dart';

class ForwardMarksArchive {
  ComponentConfig dbConfig;
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');

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

  mongo.Db get db => dbConfig.db;

  /// Insert data into the db.  Data is upserted for each (asOfDate, curveId)
  /// pair.
  /// <p>One document format:
  /// {
  ///   'asOfDate': 'yyyy-mm-dd',
  ///   'curveId': 'elec|iso:ne|ptid:4011|lmp|da',
  ///   'months': ['2019-01', '2019-02', ...],
  ///   'buckets': {
  ///     '5x16': [89.10, 86.25, ...],
  ///     '2x16H': [...],
  ///     '7x8': [...],
  ///   }
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
  ///
  void checkDocument(Map<String, dynamic> document) {
    var keys = document.keys.toSet();
    var mustHaveKeys = <String>{'asOfDate', 'curveId', 'months'};
    if (!keys.containsAll(mustHaveKeys)) {
      throw ArgumentError(
          'Document ${document} must contain asOfDate, curveId, months');
    }

    // check that months start from prompt month
    var month0 = Month.parse((document['asOfDate'] as String).substring(0, 7),
        fmt: _isoFmt);
    var month1 =
        Month.parse((document['months'] as List).first as String, fmt: _isoFmt);
    var monthN =
        Month.parse((document['months'] as List).last as String, fmt: _isoFmt);
    if (month0.next != month1) {
      throw ArgumentError('Months must start with prompt month.');
    }

    // check that month1 is after asOfDate
    var asOfDate = Date.parse(document['asOfDate']);
    if (!asOfDate.start.isBefore(month1.start)) {
      throw ArgumentError('asOfDate ');
    }

    // check that the bucket names are valid
    var bucketKeys = keys.difference(mustHaveKeys);
    var validBuckets = {'7x24', '5x16', '2x16H', '7x8'};
    if (bucketKeys.difference(validBuckets).isNotEmpty) {
      throw ArgumentError('Invalid buckets $bucketKeys');
    }

    // check that all bucketKeys have matching dimensions
    var n = (document['months'] as List).length;
    for (var key in bucketKeys) {
      if ((document[key] as List).length != n) {
        throw ArgumentError('Length of $key doesn\'t match length of months '
            'for curveId ${document['curveId']} as of $asOfDate');
      }
    }

    // A bit arbitrary, but check that you always mark until December
    if (monthN.month != 12) {
      throw ArgumentError('Need to mark until December ${monthN.year}.');
    }
  }

  void setup() async {
    await db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'curveId': 1, 'asOfDate': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'asOfDate': 1});
    await dbConfig.db.close();
  }
}
