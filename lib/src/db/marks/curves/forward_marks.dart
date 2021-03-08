library db.marks.forward_marks;

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';
import 'package:dama/dama.dart';
import 'package:timezone/timezone.dart';

class ForwardMarksArchive {
  ComponentConfig dbConfig;

  /// Marks are inserted into the db for a given (curveId, fromDate) tuple.
  /// Not all curves have marks updated every day.
  ///
  ForwardMarksArchive({this.dbConfig, this.marksAbsTolerance = 1E-6}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'marks'
      ..collectionName = 'forward_marks';
  }

  mongo.Db get db => dbConfig.db;
  num marksAbsTolerance;

  final _setEq = const SetEquality();

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
    for (var newDocument in data) {
      checkDocument(newDocument);
      var fromDate = newDocument['fromDate'] as String;
      var curveId = newDocument['curveId'] as String;

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
    // If the end term is different, need to update because it's a curve
    // extension.
    var term0 = document['terms'] as List;
    var term1 = newDocument['terms'] as List;
    if (term0.last != term1.last) return true;

    if (isPriceCurve(newDocument['curveId'] as String)) {
      /// Price curves need to be treated specially because of
      /// daily vs. monthly marks.  The old document may have monthly values
      /// where a new document has daily values.  That doesn't make them
      /// different.
      return _needToInsertPriceCurve(document, newDocument);
    }

    /// For non-price curves (e.g. hourlyshape, volatility surfaces)
    /// which only have monthly terms, the following block will never fail.
    /// It will also terminate because the last terms are equal.
    var i = 0;
    while (term0[i] != term1.first) {
      i++;
    }

    var values0 = document['buckets'];
    var values1 = newDocument['buckets'];
    for (var bucket in values0.keys) {
      var x0 = values0[bucket].sublist(i) as List;
      var x1 = values1[bucket] as List;
      // It's either a volatilitySurface, or hourlyShape document.
      // Need to compare individual elements which are themselves lists.
      for (var i = 0; i < x0.length; i++) {
        var x0i = x0[i] as List;
        for (var j = 0; j < x0i.length; j++) {
          if (!((x0i[j] as num).isCloseTo(x1[i][j] as num,
              absoluteTolerance: marksAbsTolerance))) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// For curves that have daily and monthly granularity, i.e. price curves.
  bool _needToInsertPriceCurve(
      Map<String, dynamic> document, Map<String, dynamic> newDocument) {
    // convert to a price curve (expensive), but simplest to do the
    // checking.
    var pc0 = PriceCurve.fromMongoDocument(document, UTC);
    var pc1 = PriceCurve.fromMongoDocument(newDocument, UTC);
    var aux = pc0.align(pc1);

    for (var x in aux) {
      var a = x.value.item1;
      var b = x.value.item2;
      if (!_setEq.equals(a.keys.toSet(), b.keys.toSet())) {
        return true;
      }
      for (var bucket in a.keys) {
        if (!a[bucket]
            .isCloseTo(b[bucket], absoluteTolerance: marksAbsTolerance)) {
          return true;
        }
      }
    }

    return false;
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
    var fromDate = Date.parse(document['fromDate'] as String);

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

  // Interval _parseTerm(String x) {
  //   if (x.length == 7) {
  //     return Month.parse(x);
  //   } else if (x.length == 10) {
  //     return Date.parse(x);
  //   } else {
  //     throw ArgumentError('Unknown interval $x');
  //   }
  // }

  void setup() async {
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'curveId': 1, 'fromDate': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'fromDate': 1});
  }
}
