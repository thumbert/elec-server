library api.other.forward_marks;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/marks/composite_curves.dart';
import 'package:elec_server/src/db/marks/curves/forward_marks.dart';
import 'package:elec_server/src/generated/timeseries.pb.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:more/cache.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart' as dama;
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
import '../../src/utils/api_response.dart';
import 'package:elec_server/src/db/marks/curve_attributes.dart' as ca;
import 'package:elec/src/time/shape/hourly_shape.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';

@ApiClass(name: 'forward_marks', version: 'v1')
class ForwardMarks {
  mongo.Db db;
  mongo.DbCollection coll, collCurveId;

  final log = Logger('ForwardMarks API');

  /// Cache with curve details to be used by composite curves.
  Cache<String, Map<String, dynamic>> curveIdCache;

  /// Cache with curve values.  The key is: (asOfDate, curveId)
  /// TODO: if curves are resubmitted intra-day, they need be removed from the cache
  Cache<Tuple2<Date, String>, MarksCurve> marksCache;

  /// Decided to do the composite curve calculation here (on the server side)
  /// and not on the client side.
  ForwardMarks(this.db) {
    coll = db.collection('forward_marks');

    collCurveId = db.collection('curve_ids');
    curveIdCache =
        Cache<String, Map<String, dynamic>>.lru(loader: _curveIdCacheLoader);
    marksCache = Cache<Tuple2<Date, String>, MarksCurve>.lru(
        loader: (x) => _getForwardCurve(x.item1, x.item2));
  }

  /// Get the forward curve as of a given date.  Return all marked buckets and
  /// terms.  Return the mongodb document as json.
  ///
  /// NOTE: Implementing intra-day marks is complicated by the cache and the
  /// design to return the last value in the db.  There needs to be another
  /// collection: forward_marks_intraday that has to be checked before the
  /// call to the cache is made.  If there is an element in that collection,
  /// return it from there instead of the cache.
  ///
  @ApiMethod(path: 'curveId/{curveId}/asOfDate/{asOfDate}')
  Future<ApiResponse> getForwardCurve(String curveId, String asOfDate) async {
    var aux = await marksCache.get(Tuple2(Date.parse(asOfDate), curveId));
    var out = aux.toMongoDocument(Date.parse(asOfDate), curveId);
    out.remove('fromDate');
    out.remove('curveId');
    return ApiResponse()..result = json.encode(out);
  }

  /// Return a document associated with a forward curve for only one bucket.
  /// If the bucket doesn't exist in the database, calculate it.
  ///
  @ApiMethod(path: 'curveId/{curveId}/bucket/{bucket}/asOfDate/{asOfDate}')
  Future<ApiResponse> getForwardCurveForBucket(
      String curveId, String bucket, String asOfDate) async {
    var aux = await _getForwardCurve(Date.parse(asOfDate), curveId);
    if (aux is MarksCurveEmpty) return ApiResponse()..result = '{}';
    var _bucket = Bucket.parse(bucket);
    var out = <String, dynamic>{};
    if (aux.buckets.contains(_bucket)) {
      // lucky, return what you have already in the db
      out = aux.toMongoDocument(Date.parse(asOfDate), curveId);
      out['buckets'] = {bucket: out['buckets'][bucket]};
    } else {
      // this bucket is not in the database, it needs to be computed
      if (aux is PriceCurve) {
        // for price curves only
        var data = PriceCurve();
        // if the buckets are not standard, calculate them here
        for (var term in aux.intervals) {
          var hourlyValues = aux.toHourly().window(term);
          if (hourlyValues.isNotEmpty) {
            var value = dama.mean(hourlyValues
                .where((e) => _bucket.containsHour(e.interval))
                .map((e) => e.value));
            data.add(IntervalTuple(term, {_bucket: value}));
          }
        }
        out = data.toMongoDocument(Date.parse(asOfDate), curveId);
      }
    }
    out.remove('fromDate');
    out.remove('curveId');
    return ApiResponse()..result = json.encode(out);
  }

  /// Get all the existing curve ids in the database, sorted
  @ApiMethod(path: 'curveIds')
  Future<List<String>> getCurveIds() async {
    var aux = await coll.distinct('curveId');
    var res = <String>[...(aux['values'] as List)];
    return res..sort();
  }

  /// Get all the curveIds that match a given pattern.
  @ApiMethod(path: 'curveIds/pattern/{pattern}')
  Future<List<String>> getCurveIdsContaining(String pattern) async {
    var aux = await coll.distinct('curveId');
    var res = <String>[
      ...(aux['values'] as List).where((e) => e.contains(pattern)),
    ];
    return res..sort();
  }

  /// Get the dates when a given curve was marked
  @ApiMethod(path: 'curveId/{curveId}/fromDates')
  Future<List<String>> getFromDatesForCurveId(String curveId) async {
    var pipeline = [
      {
        '\$match': {
          'curveId': {'\$eq': curveId},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'fromDate': 1,
        }
      },
      {
        '\$sort': {'fromDate': -1},
      },
    ];
    return await coll
        .aggregateToStream(pipeline)
        .map((e) => e['fromDate'] as String)
        .toList();
  }

  /// Get all the curves that were marked on this date
  @ApiMethod(path: 'fromDate/{fromDate}/curveIds')
  Future<List<String>> getCurveIdsForFromDate(String fromDate) async {
    var pipeline = [
      {
        '\$match': {
          'fromDate': {'\$eq': Date.parse(fromDate).toString()},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'curveId': 1,
        }
      },
      {
        '\$sort': {'curveId': 1},
      },
    ];
    return await coll
        .aggregateToStream(pipeline)
        .map((e) => e['curveId'] as String)
        .toList();
  }

  /// Get the buckets marked for one curve.
  Future<Set<String>> getBucketsMarked(String curveId) async {
    var buckets = ca.getBucketsMarked(curveId);
    if (ca.getBucketsMarked(curveId).isNotEmpty) return buckets;

    // fall back procedure
    var query = mongo.where
      ..eq('curveId', curveId)
      ..excludeFields(['_id']);
    var res = await coll.findOne(query);
    if (res == null) return <String>{};
    if (res.containsKey('buckets')) {
      return res['buckets'].keys.toSet();
    } else if (res.containsKey('children')) {
      // if it's a composite curve, look at the first child
      return getBucketsMarked(res['children'].first);
    }

    return <String>{};
  }

  /// For composite curves (curves with children), it retrieves each children
  /// and then combines them.
  /// Takes ~ 20 ms for a simple curve and ~ 95 ms for a composite curve.
  ///
  /// Return a map with shape:
  /// ```
  /// {
  ///   'terms': ['2020-01-01', ...],
  ///   'buckets': {
  ///     '5x16': [...],
  ///     '2x16H': [...],
  ///     '7x8': [...],
  ///   }
  /// }
  /// ```
  /// [asOfDate] is an UTC date, as there is no curve information yet
  Future<MarksCurve> _getForwardCurve(Date asOfDate, String curveId) async {
    var curveDetails = await curveIdCache.get(curveId) ?? {};
    if (curveDetails.isEmpty) {
      log.severe('No curve details for curveId: $curveId');
    }

    /// for a composite curve (a curve with children)
    if (curveDetails.containsKey('children')) {
      return _getForwardCurveComposite(asOfDate, curveDetails);
    }

    /// for a simple (not composite) curve
    var x = await ForwardMarksArchive.getDocument(
        asOfDate.toString(), curveId, coll);

    /// If this curveId doesn't exist, bail out.
    if (x.isEmpty) {
      log.severe('No marks for curveId: $curveId, asOfDate: $asOfDate');
      return MarksCurveEmpty();
    }
    var location = getLocation(curveDetails['tzLocation']);
    // now asOfDate becomes localized
    asOfDate =
        Date(asOfDate.year, asOfDate.month, asOfDate.day, location: location);
    MarksCurve curve;
    if (curveId.contains('volatility')) {
      curve = toVolatilitySurface(x, location);
      // return from prompt month forward
      var start = Month.fromTZDateTime(asOfDate.start).next.start;
      var end = (curve as VolatilitySurface).terms.last.end;
      (curve as VolatilitySurface).window(Interval(start, end));
    } else if (curveId.contains('hourlyshape')) {
      curve = toHourlyShape(x, location);
      // return from cash month forward
      var start = TZDateTime(location, asOfDate.year, asOfDate.month);
      var end = (curve as HourlyShape).data.last.interval.end;
      (curve as HourlyShape).window(Interval(start, end));
    } else {
      // return from next day after asOfDate
      curve = toPriceCurve(x, asOfDate, location);
    }

    return curve;
  }

  /// Get a composite curve.  For now only support addition of two children.
  Future<MarksCurve> _getForwardCurveComposite(
      Date asOfDate, Map<String, dynamic> curveDetails) async {
    var location = getLocation(curveDetails['tzLocation']);
    if (curveDetails['rule'] == '[0] + [1]') {
      String child0 = curveDetails['children'][0];
      String child1 = curveDetails['children'][1];
      return _add2(asOfDate, child0, child1, location);
    } else {
      throw ArgumentError('Rule ${curveDetails['rul']} not supported yet');
    }
  }

  /// Add two PriceCurve children.
  Future<PriceCurve> _add2(
      Date asOfDate, String child0, String child1, Location location) async {
    PriceCurve c0 = await marksCache.get(Tuple2(asOfDate, child0));
    PriceCurve c1 = await marksCache.get(Tuple2(asOfDate, child1));
    return c0 + c1;
  }

  /// Loader for [curveIdCache] with all curveDetails.  Returns [null] if
  /// curve doesn't exist.
  Future<Map<String, dynamic>> _curveIdCacheLoader(String curveId) {
    return collCurveId.findOne({'curveId': curveId});
  }

  /// Take a document for an hourly shape and convert it
  HourlyShape toHourlyShape(Map<String, dynamic> document, Location location) {
    return HourlyShape.fromJson(document, location);
  }

  /// Take a Mongo document for a price curve and convert it to a [PriceCurve].
  /// Keep only terms after [asOfDate].  If the cash month is marked with a
  /// monthly value, break it into dailies and return only the days after
  /// [asOfDate].
  ///
  /// [asOfDate] is localized.
  PriceCurve toPriceCurve(
      Map<String, dynamic> document, Date asOfDate, Location location) {
    var buckets = {for (var b in document['buckets'].keys) b: Bucket.parse(b)};
    final bKeys = buckets.keys.toList();
    var terms = document['terms'] as List;
    var xs = <IntervalTuple<Map<Bucket, num>>>[];
    for (var i = 0; i < terms.length; i++) {
      var one = {
        for (var bucket in bKeys)
          buckets[bucket]: document['buckets'][bucket][i] as num
      };
      Interval term;
      if (terms[i].length == 7) {
        term = Month.parse(terms[i], location: location);
        if (term.end.isAfter(asOfDate.start)) {
          /// If the cash month is marked with a monthly mark, return it.
          xs.add(IntervalTuple(term, one));
        }
      } else if (terms[i].length == 10) {
        term = Date.parse(terms[i], location: location);
        if (term.start.isAfter(asOfDate.start)) {
          xs.add(IntervalTuple(term, one));
        }
      } else {
        throw ArgumentError('Unsupported term ${terms[i]}');
      }
    }
    var out = PriceCurve.fromIterable(xs);

    if (xs.first.interval is Month) {
      /// Always break the cash month into days, to ensure the returned
      /// PriceCurve is from [asOfDate] forwards.
      out = out.expandToDaily(xs.first.interval);
      var interval = Interval(asOfDate.end, out.last.interval.end);
      out = PriceCurve.fromIterable(out.window(interval));
    }
    return out;
  }

  /// Convert a document to a [VolatilitySurface].
  VolatilitySurface toVolatilitySurface(
      Map<String, dynamic> document, Location location) {
    if (!document.containsKey('strikeRatios')) {
      throw ArgumentError('Invalid document, not a volatility surface');
    }
    return VolatilitySurface.fromJson(document, location: location);
  }
}

// Return a Map of maps, each entry is in the form {bucket: {'yyyy-mm': num}}
// Future<Map<String, Map<String, num>>> _getForwardCurveBuckets(
//     Date asOfDate, String curveId, List<String> buckets) async {
//   var data = await _getForwardCurve(asOfDate, curveId);
//   var out = <String, Map<String, num>>{};
//
//   if (data is PriceCurve) {
//     return data.;
//   } else {
//     return data.toJson()
//   }
//
//
//   if (data is MarksCurveEmpty) return out;
//
//
//   var terms = data['terms'] as List;
//   var _buckets = (data['buckets'] as Map).keys;
//
//   for (var bucket in buckets) {
//     var one = <String, num>{};
//     if (_buckets.contains(bucket)) {
//       /// the bucket is stored in the db
//       var values = data['buckets'][bucket] as List;
//       for (var i = 0; i < terms.length; i++) {
//         one[terms[i]] = values[i];
//       }
//     } else {
//       /// the bucket must exist in the [curveDefinitions]
//       /// if it doesn't exist, return empty {}
//       var curveDefs = curveDefinitions[curveId] ?? curveDefinitions['_'];
//       if (curveDefs['bucketDefs'].containsKey(bucket.toLowerCase())) {
//         var location = getLocation(curveDefs['location']);
//         var bucketNames =
//             (curveDefs['bucketDefs'][bucket.toLowerCase()] as List)
//                 .cast<String>();
//         var buckets = bucketNames.map((name) => Bucket.parse(name));
//         for (var i = 0; i < terms.length; i++) {
//           var month = Month.parse(terms[i], fmt: _isoFmt, location: location);
//           var hours =
//               buckets.map((b) => b.countHours(month)).toList().cast<num>();
//           var values = bucketNames.map((b) => data['buckets'][b][i] as num);
//           one[terms[i]] = dama.weightedMean(values, hours);
//         }
//       }
//     }
//     out[bucket] = one;
//   }
//
//   return out;
// }

// /// Calculate the bucket prices for individual strips.  Return a Map of
// /// {bucket: {strip: value}} elements.
// /// [data] is the result of the _getForwardCurveBuckets
// /// If any of the strips aren't marked, don't return them.
// Future<Map<String, Map<String, num>>> _calculateBucketsStrips(String curveId,
//     Map<String, Map<String, num>> data, List<String> strips) async {
//   var out = <String, Map<String, num>>{};
//   for (var bucket in data.keys) {
//     var one = <String, num>{};
//     var curveDef = curveDefinitions[curveId] ?? curveDefinitions['_'];
//     var location = getLocation(curveDef['location']);
//     var bucketObj = Bucket.parse(bucket);
//     for (var term in strips) {
//       try {
//         var months = parseTerm(term.trim(), tzLocation: location)
//             .splitLeft((dt) => Month.fromTZDateTime(dt));
//         var values =
//             months.map((month) => data[bucket][month.toIso8601String()]);
//         var hours = months.map((month) => bucketObj.countHours(month));
//         if (values.any((e) => e == null)) continue;
//         one[term] = dama.weightedMean(values, hours);
//       } catch (e) {
//         print(e);
//       }
//     }
//     out[bucket] = one;
//   }
//
//   return out;
// }

/// Get a strip price (e.g. Jan20-Feb20) between a start and end date.
/// If the bucket is not primary, then what?
//  @ApiMethod(
//      path:
//      'curveId/{curveId}/bucket/{bucket}/strip/{strip}/start/{startDate}/end/{endDate}')
//  Future<ApiResponse> getStripValueForDateRange(
//      String curveId, String bucket, String strip, String startDate, String endDate) async {
//    /// need to get the strip from the db for a series of dates
//  }

//  /// TODO:
//  Future<ApiResponse> getHistoricalValueForTermBucket(String asOfDate,
//      String curveId, String term, String bucket) async {
//    var query = where
//      ..gte('date', Date.parse(asOfDate).toString())
//      ..eq('curveId', curveId)
//      ..fields(['months', bucket]);
//    var res = await coll.find(query).toList();
//    return ApiResponse()..result = json.encode(res);
//  }

// TODO: return only one bucket, & return only a month,bucket historically

// /// Return the prices for this curveId for the buckets requested.
// /// [buckets] need to be separated by '_', e.g. '5x16_7x24_offpeak'
// /// Return a map of {bucket: {'yyyy-mm': value, ...}
// /// If the bucket doesn't exist in the database, calculate it
// /// based on the curveDefinitions, for example calculate the offpeak and
// /// 7x24 bucket.
// @ApiMethod(path: 'curveId/{curveId}/buckets/{buckets}/asOfDate/{asOfDate}')
// Future<ApiResponse> getForwardCurveForBuckets(
//     String curveId, String buckets, String asOfDate) async {
//   var _buckets = buckets.split('_');
//   var data =
//       await _getForwardCurveBuckets(Date.parse(asOfDate), curveId, _buckets);
//   return ApiResponse()..result = json.encode(data);
// }

// /// Calculate the curve value for a list of strips, e.g. 'Jan19-Feb19_Q1,2020'
// /// Strips should be a list of semicolon separated terms.  If the curve
// /// is not defined for some months in the strip, ignore that strip in the
// /// response.
// /// [buckets] is a list of '_' separated bucket names, e.g. '7x24_Offpeak_7x8'
// ///
// @ApiMethod(
//     path:
//         'curveId/{curveId}/buckets/{buckets}/asOfDate/{asOfDate}/strips/{strips}/markType/{markType}')
// Future<ApiResponse> getForwardCurveForBucketsStrips(String curveId,
//     String buckets, String asOfDate, String strips, String markType) async {
//   var _strips = strips.split('_');
//   var _buckets = buckets.split('_');
//   var data =
//       await _getForwardCurveBuckets(Date.parse(asOfDate), curveId, _buckets);
//   var out = await _calculateBucketsStrips(curveId, data, _strips);
//   return ApiResponse()..result = json.encode(out);
// }
