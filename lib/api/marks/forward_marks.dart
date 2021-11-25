library api.other.forward_marks;

import 'package:shelf/shelf.dart';
import 'dart:async';
import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/marks/curves/forward_marks.dart';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:more/cache.dart';
import 'package:date/date.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
import 'package:elec_server/src/db/marks/curve_attributes.dart' as ca;
import 'package:elec/src/time/shape/hourly_shape.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';

typedef CompositionRule = Future<PriceCurve> Function(
    Date asOfDate, Map<String, dynamic> curveDetails);

final _curveCompositionRules = <String, CompositionRule>{
  '[0] + [1]': ForwardMarks._add2,
  '[0] - [1]': ForwardMarks._sub2,
  '[0] + [1] + [0] * [2]': ForwardMarks._nodalLmp,
};

class ForwardMarks {
  mongo.Db db;
  late mongo.DbCollection coll;
  late mongo.DbCollection collCurveId;

  final log = Logger('ForwardMarks API');

  /// Cache with curve details to be used by composite curves.
  /// TODO:  What to do if there is no curve?
  static late Cache<String, Map<String, dynamic>?> curveIdCache;

  /// Cache with curve values.  The key is: (asOfDate, curveId)
  /// TODO: if curves are resubmitted intra-day, they need be removed from the cache
  static late Cache<Tuple2<Date, String>, MarksCurve> marksCache;

  final headers = {
    'Content-Type': 'application/json',
  };

  /// Decided to do the composite curve calculation here (on the server side)
  /// and not on the client side.
  ForwardMarks(this.db) {
    coll = db.collection('forward_marks');

    collCurveId = db.collection('curve_ids');
    curveIdCache = Cache<String, Map<String, dynamic>?>.lru(
        loader: _curveIdCacheLoader, maximumSize: 10000);
    marksCache = Cache<Tuple2<Date, String>, MarksCurve>.lru(
        loader: (x) => getForwardCurve(x.item1, x.item2), maximumSize: 10000);
  }

  Router get router {
    final router = Router();

    /// Get the forward curve as of a given date.  Return all marked buckets and
    /// terms.  Return the mongodb document as json.
    ///
    /// NOTE: Implementing intra-day marks is complicated by the cache and the
    /// design to return the last value in the db.  There needs to be another
    /// collection: forward_marks_intraday that has to be checked before the
    /// call to the cache is made.  If there is an element in that collection,
    /// return it from there instead of the cache.  Or you can try to invalidate
    /// the cache.
    ///
    router.get('/curveId/<curveId>/asOfDate/<asOfDate>',
        (Request request, String curveId, String asOfDate) async {
      var aux = await marksCache.get(Tuple2(Date.parse(asOfDate), curveId));
      var out = aux.toMongoDocument(Date.parse(asOfDate), curveId);
      out.remove('fromDate');
      out.remove('curveId');
      return Response.ok(json.encode(out), headers: headers);
    });

    /// Get all the existing curve ids in the database, sorted
    router.get('/curveIds', (Request request) async {
      var aux = await coll.distinct('curveId');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    /// Get all the curveIds that match a given pattern, sorted
    router.get('/curveIds/pattern/<pattern>',
        (Request request, String pattern) async {
      var aux = await getCurveIdsContaining(pattern);
      aux.sort();
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get all the dates a curve was marked.
    router.get('/curveId/<curveId>/fromDates',
        (Request request, String curveId) async {
      var aux = await getFromDatesForCurveId(curveId);
      aux.sort();
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get all the curves that were marked on this date
    router.get('/fromDate/<fromDate>/curveIds',
        (Request request, String fromDate) async {
      var aux = await getCurveIdsForFromDate(fromDate);
      aux.sort();
      return Response.ok(json.encode(aux), headers: headers);
    });

    /// Get the size of the forward marks cache
    router.get('/cache-size', (Request request) async {
      var size = await marksCache.size();
      return Response.ok(json.encode(size), headers: headers);
    });

    /// Invalidate an entry in the marks cache
    router.get('/cache-invalidate/curveId/<curveId>/asOfDate/<asOfDate>',
        (Request request, String curveId, String asOfDate) async {
      await marksCache.invalidate(Tuple2(Date.parse(asOfDate), curveId));
      return Response.ok(json.encode('Success'), headers: headers);
    });

    return router;
  }

  /// Get all the curveIds that match a given pattern.
  Future<List<String>> getCurveIdsContaining(String pattern) async {
    var aux = await coll.distinct('curveId');
    var res = (aux['values'] as List)
        .cast<String>()
        .where((e) => e.contains(pattern))
        .toList();
    return res..sort();
  }

  /// Get all the dates a curve was marked.
  Future<List<String?>> getFromDatesForCurveId(String curveId) async {
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
        .map((e) => e['fromDate'] as String?)
        .toList();
  }

  /// Get all the curves that were marked on this date
  Future<List<String?>> getCurveIdsForFromDate(String fromDate) async {
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
        .map((e) => e['curveId'] as String?)
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
      return (res['buckets'] as Map<String, dynamic>).keys.toSet();
    } else if (res.containsKey('children')) {
      // if it's a composite curve, look at the first child
      return getBucketsMarked(res['children'].first as String);
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
  Future<MarksCurve> getForwardCurve(Date asOfDate, String curveId) async {
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
    var location = curveDetails['tzLocation'] == 'UTC'
        ? UTC
        : getLocation(curveDetails['tzLocation'] as String);
    // now asOfDate becomes localized
    asOfDate =
        Date(asOfDate.year, asOfDate.month, asOfDate.day, location: location);
    MarksCurve curve;
    if (curveId.contains('volatility')) {
      curve = toVolatilitySurface(x, location);
      // return from prompt month forward
      var start = Month.fromTZDateTime(asOfDate.start).next.start;
      var end = (curve as VolatilitySurface).terms.last.end;
      curve.window(Interval(start, end));
    } else if (curveId.contains('hourlyshape')) {
      curve = toHourlyShape(x, location);
      // return from cash month forward
      var start = TZDateTime(location, asOfDate.year, asOfDate.month);
      var end = (curve as HourlyShape).data.last.interval.end;
      curve.window(Interval(start, end));
    } else {
      // return from next day after asOfDate
      curve = toPriceCurve(x, asOfDate, location);
    }

    return curve;
  }

  /// Get a composite curve.  For now only support addition of two children.
  Future<MarksCurve> _getForwardCurveComposite(
      Date asOfDate, Map<String, dynamic> curveDetails) async {
    var rule = curveDetails['rule'];
    if (_curveCompositionRules.containsKey(rule)) {
      return _curveCompositionRules[rule]!(asOfDate, curveDetails);
    }
    print('Rule $rule not supported yet for ${curveDetails['curveId']}');
    return MarksCurveEmpty();
  }

  /// Add two PriceCurve children.  Used to calculate the LMP curve from
  /// parent and basis curves.
  static Future<PriceCurve> _add2(
      Date asOfDate, Map<String, dynamic> curveDetails) async {
    var curveDetails0 = curveDetails['children'][0] as String;
    var curveDetails1 = curveDetails['children'][1] as String;
    var c0 =
        await marksCache.get(Tuple2(asOfDate, curveDetails0)) as PriceCurve;
    var c1 =
        await marksCache.get(Tuple2(asOfDate, curveDetails1)) as PriceCurve;
    return c0 + c1;
  }

  /// Subtract two PriceCurve children.  Used to calculate a basis curve.
  static Future<PriceCurve> _sub2(
      Date asOfDate, Map<String, dynamic> curveDetails) async {
    var curveDetails0 = curveDetails['children'][0] as String;
    var curveDetails1 = curveDetails['children'][1] as String;
    var c0 =
        await marksCache.get(Tuple2(asOfDate, curveDetails0)) as PriceCurve;
    var c1 =
        await marksCache.get(Tuple2(asOfDate, curveDetails1)) as PriceCurve;
    return c0 - c1;
  }

  /// Calculate Nodal LMP from parent/hub [0], congestion to hub [1],
  /// and loss factor [2] curves.  Return [0] + [1] + [0] * [2]
  static Future<PriceCurve> _nodalLmp(
      Date asOfDate, Map<String, dynamic> curveDetails) async {
    var curveDetails0 = curveDetails['children'][0] as String;
    var curveDetails1 = curveDetails['children'][1] as String;
    var curveDetails2 = curveDetails['children'][2] as String;
    var c0 =
        await marksCache.get(Tuple2(asOfDate, curveDetails0)) as PriceCurve;
    var c1 =
        await marksCache.get(Tuple2(asOfDate, curveDetails1)) as PriceCurve;
    var c2 =
        await marksCache.get(Tuple2(asOfDate, curveDetails2)) as PriceCurve;
    return c0 + c1 + c0 * c2;
  }

  /// Loader for [curveIdCache] with all curveDetails.  Returns [null] if
  /// curve doesn't exist.
  Future<Map<String, dynamic>?> _curveIdCacheLoader(String curveId) {
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
    var buckets = {
      for (var b in document['buckets'].keys) b: Bucket.parse(b as String)
    };
    final bKeys = buckets.keys.toList();
    var terms = document['terms'] as List;
    var xs = <IntervalTuple<Map<Bucket, num>>>[];
    for (var i = 0; i < terms.length; i++) {
      var one = <Bucket, num>{};
      for (var bucket in bKeys) {
        num? aux = document['buckets'][bucket][i];
        if (aux != null) {
          one[buckets[bucket]!] = aux;
        }
      }

      Interval term;
      if (terms[i].length == 7) {
        term = Month.parse(terms[i] as String, location: location);
        if (term.end.isAfter(asOfDate.start)) {
          /// If the cash month is marked with a monthly mark, return it.
          xs.add(IntervalTuple(term, one));
        }
      } else if (terms[i].length == 10) {
        term = Date.parse(terms[i] as String, location: location);
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
      out = out.expandToDaily(xs.first.interval as Month);
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

// /// Return a document associated with a forward curve for only one bucket.
// /// If the bucket doesn't exist in the database, calculate it.
// router.get('/curveId/<curveId>/bucket/<bucket>/asOfDate/<asOfDate>',
//     (Request request, String curveId, String bucket,
//         String asOfDate) async {
//   var out = await getForwardCurveForBucket(curveId, bucket, asOfDate);
//   return Response.ok(json.encode(out), headers: headers);
// });

/// Return a document associated with a forward curve for only one bucket.
/// If the bucket doesn't exist in the database, calculate it.
///
// Future<Map<String, dynamic>> getForwardCurveForBucket(
//     String curveId, String bucket, String asOfDate) async {
//   var aux = await _getForwardCurve(Date.parse(asOfDate), curveId);
//   if (aux is MarksCurveEmpty) return <String, dynamic>{};
//   var _bucket = Bucket.parse(bucket);
//   var out = <String, dynamic>{};
//   if (aux.buckets.contains(_bucket)) {
//     // lucky, return what you have already in the db
//     out = aux.toMongoDocument(Date.parse(asOfDate), curveId);
//     out['buckets'] = {bucket: out['buckets'][bucket]};
//   } else {
//     // this bucket is not in the database, it needs to be computed
//     if (aux is PriceCurve) {
//       // for price curves only
//       var data = PriceCurve();
//       // if the buckets are not standard, calculate them here
//       for (var term in aux.intervals) {
//         var hourlyValues = aux.toHourly().window(term);
//         if (hourlyValues.isNotEmpty) {
//           var value = dama.mean(hourlyValues
//               .where((e) => _bucket.containsHour(e.interval as Hour))
//               .map((e) => e.value));
//           data.add(IntervalTuple(term, {_bucket: value}));
//         }
//       }
//       out = data.toMongoDocument(Date.parse(asOfDate), curveId);
//     }
//   }
//   out.remove('fromDate');
//   out.remove('curveId');
//   return out;
// }
