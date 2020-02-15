library db.marks.forward_marks;

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';
import 'package:intl/intl.dart';

class ForwardMarksArchive {
  ComponentConfig dbConfig;
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');
  final _equality = const ListEquality();

  /// Marks are inserted into the db for a given (curveId, fromDate) tuple.
  /// Not all curves have marks updated every day.
  ///
  /// TODO: Support intra-day curves (in another collection)
  ///
  ForwardMarksArchive({this.dbConfig}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'marks'
      ..collectionName = 'forward_marks';
  }

  mongo.Db get db => dbConfig.db;

  /// Insert a list of documents into the db.  Each document is sanity checked
  /// prior to insertion.  Also, a document is inserted only if needed (values
  /// change or curve extended.)
  ///
  /// <p>Document format:
  /// {
  ///   'fromDate': '2018-12-14',
  ///   'version': '2018-12-14T10:12:47.000-0500',
  ///   'curveId': 'elec|iso:ne|ptid:4011|lmp|da',
  ///   'months': ['2019-01', '2019-02', ...],
  ///   'buckets': {
  ///     '5x16': [89.10, 86.25, ...],
  ///     '2x16H': [...],
  ///     '7x8': [...],
  ///   }
  /// }
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
      for (var newDocument in data) {
        checkDocument(newDocument);
        var fromDate = newDocument['fromDate'];
        var curveId = newDocument['curveId'];
        // get the existing document
        var document = await _getForwardCurve(fromDate, curveId);
        if (needToInsert(document, newDocument)) {
          await dbConfig.coll.insert(newDocument);
          print(
              '--->  Inserted forward marks for ${curveId} as of ${fromDate} successfully');
        }
      }
      return Future.value(0);
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
  }

  /// Check if you need to insert the document or not.  You need to insert if
  /// values are different or if it's a curve extension.  Return [true] if an
  /// update is needed.
  bool needToInsert(
      Map<String, dynamic> document, Map<String, dynamic> newDocument) {
    // The new document may have different start/end months.
    // If the end month is different, need to update as it's a curve extension.
    var months0 = document['months'] as List;
    var months1 = newDocument['months'] as List;
    if (months0.last != months1.last) return true;

    var i = 0;
    while (months0[i] != months1.first) {
      i++;
    }

    var values0 = document['buckets'] as Map<String, List<num>>;
    var values1 = newDocument['buckets'] as Map<String, List<num>>;
    for (var bucket in values0.keys) {
      var x0 = values0[bucket].sublist(i);
      var x1 = values1[bucket];
      if (!_equality.equals(x0, x1)) return true;
    }

    return false;
  }

  /// Basic checks on the document structure.
  void checkDocument(Map<String, dynamic> document) {
    var keys = document.keys.toSet();
    var mustHaveKeys = <String>{'fromDate', 'curveId', 'months', 'buckets'};
    if (!keys.containsAll(mustHaveKeys)) {
      throw ArgumentError(
          'Document ${document} must contain fromDate, curveId, months');
    }

    // check that months start from prompt month
    var month0 = Month.parse((document['fromDate'] as String).substring(0, 7),
        fmt: _isoFmt);
    var month1 =
        Month.parse((document['months'] as List).first as String, fmt: _isoFmt);
    var monthN =
        Month.parse((document['months'] as List).last as String, fmt: _isoFmt);
    if (month0.next != month1) {
      throw ArgumentError('Months must start with prompt month.');
    }

    // check that month1 is after fromDate
    var fromDate = Date.parse(document['fromDate']);
    if (!fromDate.start.isBefore(month1.start)) {
      throw ArgumentError(
          'first marked month needs to be after fromDate: $document');
    }

    // check that the bucket names are valid
    var bucketKeys = (document['buckets'] as Map).keys.toSet();
    var validBuckets = {'7x24', '5x16', '2x16H', '7x8'};
    if (bucketKeys.difference(validBuckets).isNotEmpty) {
      throw ArgumentError('Invalid buckets: $bucketKeys');
    }

    // check that all bucketKeys have matching dimensions
    var n = (document['months'] as List).length;
    for (var key in bucketKeys) {
      if ((document['buckets'][key] as List).length != n) {
        throw ArgumentError('Length of $key doesn\'t match length of months '
            'for curveId ${document['curveId']} as of $fromDate');
      }
    }

    // A bit arbitrary, but check that you always mark until December
    if (monthN.month != 12) {
      throw ArgumentError('Need to mark until December ${monthN.year}.');
    }
  }

  /// Get the document for this [curveId] and [fromDate].
  Future<Map<String, dynamic>> _getForwardCurve(
      String asOfDate, String curveId) async {
    var pipeline = [
      {
        '\$match': {
          'curveId': {'\$eq': curveId},
          'fromDate': {'\$lte': Date.parse(asOfDate).toString()},
        }
      },
      {
        '\$sort': {'fromDate': -1},
      },
      {
        '\$limit': 1,
      },
      {
        '\$project': {
          '_id': 0,
          'fromDate': 0,
          'curveId': 0,
        }
      },
    ];
    var aux = await dbConfig.coll.aggregateToStream(pipeline).toList();
    return aux.first;
  }


  void setup() async {
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'curveId': 1, 'fromDate': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'fromDate': 1});
  }
}
