import 'dart:math';

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
  /// The [asOfDate] key is a UTC date, but the [MarksCurve] is in the correct
  /// [curveId] timezone.
  /// TODO: if curves are resubmitted intra-day, they need be removed from the cache
  /// or always pull current day marks in the cache.
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
        loader: _curveIdCacheLoader, maximumSize: 20000);
    marksCache = Cache<Tuple2<Date, String>, MarksCurve>.lru(
        loader: (x) => _getForwardCurve(x.item1, x.item2), maximumSize: 10000);
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
      if (aux is MarksCurveEmpty) {
        return Response.ok(json.encode({}), headers: headers);
      }
      var out = aux.toMongoDocument(Date.parse(asOfDate), curveId);
      out.remove('fromDate');
      out.remove('curveId');
      return Response.ok(json.encode(out), headers: headers);
    });

    /// Get the price of a strip and bucket between a start/end date.
    /// Only works for a PriceCurve.
    router.get(
        '/curveId/<curveId>/term/<term>/bucket/<bucket>/start/<start>/end/<end>',
        (Request request, String curveId, String term, String bucket,
            String start, String end) async {
      var _term = Term.parse(term, UTC);
      var _bucket = Bucket.parse(bucket);
      var _start = Date.parse(start, location: UTC);
      var _end = Date.parse(end, location: UTC);
      var out = await getStripPrice(curveId, _term, _bucket, _start, _end);
      return Response.ok(json.encode(out), headers: headers);
    });

    /// Get all the points of a strip and bucket between a start/end date.
    /// Only works for a PriceCurve.
    /// If you ask for a Jan21-Feb21 term, bucket 5x16, between 1Jan20 and
    /// 31Dec20 the shape of the document returned is
    /// ```dart
    /// [
    ///   {'2020-01-01': [70.1, 68.75]},
    ///   ...
    ///   {'2020-12-31': [140.1, 138.25]},
    /// ]
    /// ```
    router.get(
        '/curveId/<curveId>/term/<term>/bucket/<bucket>/start/<start>/end/<end>/values',
        (Request request, String curveId, String term, String bucket,
            String start, String end) async {
      var _term = Term.parse(term, UTC);
      var _bucket = Bucket.parse(bucket);
      var _start = Date.parse(start, location: UTC);
      var _end = Date.parse(end, location: UTC);
      var out =
          await getStripPriceValues(curveId, _term, _bucket, _start, _end);
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
    return marksCache.get(Tuple2(asOfDate, curveId));
  }

  /// Get one curve from Mongo and add it to the cache.  The loader function
  /// needs to be internal.
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

    return _formatMongoDocument(
        x, asOfDate.toString(), curveId, curveDetails['tzLocation']!);
  }

  /// Get strip price between start/end.  Only works for a [curveId] that is a
  /// [PriceCurve].  For other curve types, e.g. hourlyshape or volatility,
  /// it returns empty.
  ///
  /// Return a Map with each element in form {'yyyy-mm-dd': num}.
  Future<Map<String, num>> getStripPrice(
      String curveId, Term term, Bucket bucket, Date start, Date end) async {
    var out = <String, num>{};
    if (!ForwardMarksArchive.isPriceCurve(curveId)) {
      log.severe('CurveId $curveId is not a price curve!');
      return out;
    }
    // fill the cache with one call to the database
    await fillMarksCacheBulk(curveId, start, end);

    // need to set the term to the curve's native timezone
    var curveDetails = await curveIdCache.get(curveId) ?? {};
    if (curveDetails.isEmpty) {
      log.severe('No curve details for curveId: $curveId');
    }
    String tzLocation = curveDetails['tzLocation']!;
    var location = tzLocation == 'UTC' ? UTC : getLocation(tzLocation);
    term = Term.fromInterval(term.interval.withTimeZone(location));

    var date = start;
    while (!date.isAfter(end)) {
      var aux = await marksCache.get(Tuple2(date, curveId));
      if (aux is PriceCurve) {
        // could be a MarksCurveEmpty
        out[date.toString()] = aux.value(term.interval, bucket);
      }
      date = date.next;
    }
    return out;
  }

  /// Get the price values for the strip between start/end.
  /// Only works for a [curveId] that is a [PriceCurve].  For other curve types,
  /// e.g. hourlyshape or volatility, it returns empty.
  ///
  Future<Map<String, List<num>>> getStripPriceValues(
      String curveId, Term term, Bucket bucket, Date start, Date end) async {
    var out = <String, List<num>>{};
    if (!ForwardMarksArchive.isPriceCurve(curveId)) {
      log.severe('CurveId $curveId is not a price curve!');
      return out;
    }
    // fill the cache with one call to the database
    await fillMarksCacheBulk(curveId, start, end);

    // need to set the term to the curve's native timezone
    var curveDetails = await curveIdCache.get(curveId) ?? {};
    if (curveDetails.isEmpty) {
      log.severe('No curve details for curveId: $curveId');
    }
    String tzLocation = curveDetails['tzLocation']!;
    var location = tzLocation == 'UTC' ? UTC : getLocation(tzLocation);
    term = Term.fromInterval(term.interval.withTimeZone(location));

    var date = start;
    while (!date.isAfter(end)) {
      var aux = await marksCache.get(Tuple2(date, curveId));
      if (aux is PriceCurve) {
        // could be a MarksCurveEmpty
        out[date.toString()] =
            aux.points(bucket, interval: term.interval).values.toList();
      }
      date = date.next;
    }
    return out;
  }

  /// Make one call to the database and fill the cache for a [curveId]
  /// multiple days.  Reinsert exiting days in the cache if they fall between
  /// [start] and [end] dates.
  Future<void> fillMarksCacheBulk(String curveId, Date start, Date end) async {
    var curveDetails = await curveIdCache.get(curveId) ?? {};
    if (curveDetails.isEmpty) {
      log.severe('No curve details for curveId: $curveId');
    }
    String tzLocation = curveDetails['tzLocation']!;
    var curveIds = <String>[];

    /// for composite curves, need to get all the children
    if (curveDetails.containsKey('children')) {
      curveIds = curveDetails['children'];
    } else {
      curveIds = [curveId];
    }
    var days = start.upTo(end);
    for (var curveId in curveIds) {
      var docs = await ForwardMarksArchive.getDocumentsOneCurveStartEnd(
          curveId, coll, start.toString(), end.toString());
      if (docs.isEmpty) {
        log.warning('Curve $curveId is not marked before $end');
        return;
      } else if (docs.length == 1) {
        // all days have the same curve, easy
        for (var day in days) {
          var value = _formatMongoDocument(
              docs.first, day.toString(), curveId, tzLocation);
          await marksCache.set(Tuple2(day, curveId), value);
        }
      } else {
        var i = 1;
        for (var day in days) {
          var anchorDate = docs[min(i, docs.length - 1)]['fromDate'];
          if (day.toString().compareTo(anchorDate) == 0) {
            i = min(i + 1, docs.length);
          }
          var value = _formatMongoDocument(
              docs[i - 1], day.toString(), curveId, tzLocation);
          await marksCache.set(Tuple2(day, curveId), value);
        }
      }
    }
  }

  /// Prepare the Mongo document to store in the cache.
  MarksCurve _formatMongoDocument(Map<String, dynamic> document,
      String asOfDate, String curveId, String tzLocation) {
    /// If this curveId doesn't exist, bail out.
    if (document.isEmpty) {
      log.warning('No marks for curveId: $curveId, asOfDate: $asOfDate');
      return MarksCurveEmpty();
    }
    var location = tzLocation == 'UTC' ? UTC : getLocation(tzLocation);
    // localize asOfDate in the timezone of the curve
    var _asOfDate = Date.parse(asOfDate, location: location);
    MarksCurve curve;
    if (ForwardMarksArchive.isPriceCurve(curveId)) {
      curve = _toPriceCurve(document, _asOfDate);
    } else {
      if (curveId.contains('volatility')) {
        curve = _toVolatilitySurface(document, _asOfDate);
      } else if (curveId.contains('hourlyshape')) {
        curve = _toHourlyShape(document, _asOfDate);
      } else {
        log.severe('Unknown classification for curve $curveId');
        return MarksCurveEmpty();
      }
    }
    return curve;
  }

  /// Get a composite curve.  Support only a limited number of rules as
  /// defined in [_curveCompositionRules].
  Future<MarksCurve> _getForwardCurveComposite(
      Date asOfDate, Map<String, dynamic> curveDetails) async {
    var rule = curveDetails['rule'];
    if (_curveCompositionRules.containsKey(rule)) {
      return _curveCompositionRules[rule]!(asOfDate, curveDetails);
    }
    log.severe('Rule $rule not supported yet for ${curveDetails['curveId']}');
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
  HourlyShape _toHourlyShape(Map<String, dynamic> document, Date asOfDate) {
    var curve = HourlyShape.fromJson(document, asOfDate.location);
    var start = TZDateTime(asOfDate.location, asOfDate.year, asOfDate.month);
    var end = curve.data.last.interval.end;
    curve.window(Interval(start, end));
    return curve;
  }

  /// Take a Mongo document for a price curve and convert it to a [PriceCurve].
  /// Keep only terms after [asOfDate].  If the cash month is marked with a
  /// monthly value, break it into dailies and return only the days after
  /// [asOfDate].
  ///
  /// [asOfDate] is localized in the [PriceCurve] timezone.
  PriceCurve _toPriceCurve(Map<String, dynamic> document, Date asOfDate) {
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
        term = Month.parse(terms[i] as String, location: asOfDate.location);
        if (term.end.isAfter(asOfDate.start)) {
          /// If the cash month is marked with a monthly mark, return it.
          xs.add(IntervalTuple(term, one));
        }
      } else if (terms[i].length == 10) {
        term = Date.parse(terms[i] as String, location: asOfDate.location);
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
  /// Return values from prompt month forward.
  VolatilitySurface _toVolatilitySurface(
      Map<String, dynamic> document, Date asOfDate) {
    if (!document.containsKey('strikeRatios')) {
      throw ArgumentError('Invalid document, not a volatility surface');
    }
    var curve =
        VolatilitySurface.fromJson(document, location: asOfDate.location);
    // return from prompt month forward
    var start = Month.fromTZDateTime(asOfDate.start).next.start;
    var end = curve.terms.last.end;
    curve.window(Interval(start, end));
    return curve;
  }
}
