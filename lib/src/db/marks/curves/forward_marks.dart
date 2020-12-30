library db.marks.forward_marks;

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';
import 'package:intl/intl.dart';
import 'package:dama/dama.dart';

class ForwardMarksArchive {
  ComponentConfig dbConfig;

  /// Marks are inserted into the db for a given (curveId, fromDate) tuple.
  /// Not all curves have marks updated every day.
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
  /// change or curve extended.)  Values for the same [fromDate] and term are
  /// overwritten, no versioning exists.
  ///
  /// <p>Document format:
  /// ```
  /// {
  ///   'fromDate': '2020-06-15',
  ///   'curveId': 'elec_isone_4011_lmp_da',
  ///   'terms': ['2020-06-16', ..., '2020-07', '2020-08', ..., '2026-12'],
  ///   'buckets': {
  ///     '5x16': [27.10, 26.25, ...],
  ///     '2x16H': [...],
  ///     '7x8': [...],
  ///   }
  /// }
  ///```
  ///
  /// Note that the elements of the 'terms' field can be either a date
  /// (yyyy-mm-dd) or a month (yyyy-mm).  They should be always ordered.
  /// In general, every term form that can be parsed by [Term] is supported.
  /// Marks should exist from prompt day forward.  You can mark the cash
  /// month as one term with the understanding that it will be expanded to
  /// a list of daily marks as needed.
  ///
  /// For an 'hourlyShape' document, each entry in the buckets List is a List with
  /// the shape factors for corresponding (term,bucket) tuple.
  ///
  /// For a 'volatilitySurface' document, each element of the bucket List is a
  /// List corresponding to the 'strikeRatio' field.  For example:
  /// ```
  /// {
  ///   'fromDate': '2020-06-15',
  ///   'curveId': 'elec_isone_4000_volatility_daily',
  ///   'terms': ['2020-07', '2020-08', ..., '2026-12'],
  ///   'strikeRatio': [0.5, 1, 2]
  ///   'buckets': {
  ///     '5x16': [
  ///        [48.5, 51.2, 54.7],  // for 2020-07, strikeRatio: 0.5, 1, 2
  ///        ...],
  ///     '2x16H': [...],
  ///     '7x8': [...],
  ///   }
  /// }
  ///```
  ///
  /// Each document must contain all terms and buckets, no 'partial' marking is
  /// allowed, e.g. can't submit daily marks and monthly marks separately.
  /// This may be relaxed in the future, but is not yet enabled.
  ///
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
      for (var newDocument in data) {
        checkDocument(newDocument);
        var fromDate = newDocument['fromDate'];
        var curveId = newDocument['curveId'];

        /// Get the last document with the curve, and check if you need to
        /// reinsert it.
        var document = await getDocument(fromDate, curveId, dbConfig.coll);
        if (needToInsert(document, newDocument)) {
          if (document['fromDate'] == fromDate) {
            // fromDate is already in the database, so remove the old document
            await dbConfig.coll
                .remove({'fromDate': fromDate, 'curveId': curveId});
          }
          await dbConfig.coll.insert(newDocument);
          print(
              '--->  Inserted forward marks for ${curveId} for ${fromDate} successfully');
        }
      }
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
    return Future.value(0);
  }

  /// Check if you need to insert the document or not.
  /// Curves could be submitted every day for completeness, but they are not
  /// stored if they have the same values as the day before.
  ///
  /// You need to insert if:
  /// 1) values are different up to an absolute tolerance of 10-6, or
  /// 2) if it's a curve extension.
  ///
  /// Return true if a curve insertion is needed.
  bool needToInsert(
      Map<String, dynamic> document, Map<String, dynamic> newDocument) {
    if (document.isEmpty) return true;
    // The new document may have different start/end months.
    // If the end term is different, need to update as it's a curve extension.
    var term0 = document['terms'] as List;
    var term1 = newDocument['terms'] as List;
    if (term0.last != term1.last) return true;

    var i = 0;
    while (term0[i] != term1.first) {
      i++;
    }

    var values0 = document['buckets'];
    var values1 = newDocument['buckets'];
    for (var bucket in values0.keys) {
      List x0 = values0[bucket].sublist(i);
      List x1 = values1[bucket];
      if (isPriceCurve(newDocument['curveId'])) {
        for (var i = 0; i < x0.length; i++) {
          // very strange that I have to do the 'as num' below.  It won't work
          // otherwise.
          if (!((x0[i] as num).isCloseTo(x1[i], absoluteTolerance: 1E-6))) {
            return true;
          }
        }
      } else {
        // it's either a volatilitySurface, or hourlyShape document,
        // need to compare individual elements which are themselves lists.
        for (var i = 0; i < x0.length; i++) {
          for (var j = 0; j < x1.length; j++) {
            if (!((x0[i][j] as num)
                .isCloseTo(x1[i][j], absoluteTolerance: 1E-6))) {
              return true;
            }
            // if (!_equality.equals(x0[i][j], x1[i][j])) return true;
          }
        }
      }
    }

    return false; // false = don't need to insert, no changes
  }

  /// Basic checks on the document structure.
  void checkDocument(Map<String, dynamic> document) {
    var keys = document.keys.toSet();
    var mustHaveKeys = <String>{
      'fromDate',
      'curveId',
      'buckets',
      'terms',
    };
    if (!keys.containsAll(mustHaveKeys)) {
      throw ArgumentError('Document ${document} is missing required fields.');
    }
    var fromDate = Date.parse(document['fromDate']);

    var bucketKeys = (document['buckets'] as Map).keys.toSet();

    // check that all bucketKeys have matching dimensions
    var n = (document['terms'] as List).length;
    for (var key in bucketKeys) {
      if ((document['buckets'][key] as List).length != n) {
        throw ArgumentError(
            'Length of bucket $key doesn\'t match length of terms '
            'for curveId ${document['curveId']} as of $fromDate, '
            'markType ${document['markType']}');
      }
    }
  }

  /// Get the document for this [curveId] and [fromDate].
  static Future<Map<String, dynamic>> getDocument(
      String asOfDate, String curveId, mongo.DbCollection coll) async {
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
          'curveId': 0,
          'markType': 0,
        }
      },
    ];
    var aux = await coll.aggregateToStream(pipeline).toList();
    if (aux.isEmpty) return <String, dynamic>{};
    return <String, dynamic>{...aux.first};
  }

  /// Determine if it's a simple price curve from the name
  bool isPriceCurve(String curveId) {
    if (curveId.contains('volatility') || curveId.contains('hourlyshape')) {
      return false;
    }
    return true;
  }

  void setup() async {
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'curveId': 1, 'fromDate': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'fromDate': 1});
  }
}
