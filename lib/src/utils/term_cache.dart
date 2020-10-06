library utils.term_cache;

import 'package:collection/collection.dart';
import 'package:date/date.dart';

class TermCache {
  /// Loader function that gets the (expensive) data associated with an
  /// interval.  Data is further split using the [keyAssign] function and
  /// stored into the cache.
  Future<List<Map<String, dynamic>>> Function(Interval) loader;

  /// Function to partition the data returned by the [loader] into keys for
  /// storing into the cache.  Usually this function returns a Date or a Month
  /// object. e.g. keyAssign = (e) => e['date'] as Date;
  Interval Function(Map<String, dynamic>) keyAssign;

  /// Split the interval and return the cache keys.  For example
  /// keysFromInterval = (interval) => interval.splitLeft((dt) => Date.fromTZDateTime(dt)).cast<Date>();
  List<Interval> Function(Interval) keysFromInterval;

  Map<Interval, List<Map<String, dynamic>>> _cache;

  /// A cache in the style of pacakage:more/cache.dart that stores data
  /// associated with an interval.
  ///
  TermCache(this.loader, this.keyAssign, this.keysFromInterval) {
    _cache = <Interval, List<Map<String, dynamic>>>{};
  }

  /// Domain of the cache (where the cache has values.)
  List<Interval> domain() {
    var days = _cache.keys.toList()..sort();
    return Interval.fuse(days);
  }

  /// Populate the cache for the given [interval].  Only the keys that are
  /// not in the cache are retrieved and inserted.
  ///
  /// If the loader doesn't return any data for an interval, the keys associated
  /// with that interval will contain an empty list to prevent the loader from
  /// trying to fetch that interval again in the future.
  Future<Null> set(Interval interval) async {
    var missingIntervals = interval.difference(domain());
    for (var missingInterval in missingIntervals) {
      var data = await loader(missingInterval);
      var grp = groupBy(data, keyAssign);
      var keys = keysFromInterval(missingInterval);
      for (var key in keys) {
        if (grp.containsKey(key)) {
          _cache[key] = grp[key];
        } else {
          _cache[key] = <Map<String, dynamic>>[];
        }
      }
    }
  }

  /// Get all the entries associated with this interval from the cache.
  /// Make sure you call [set] first.
  List<Map<String, dynamic>> get(Interval interval) {
    var keys = keysFromInterval(interval);
    var out = <Map<String, dynamic>>[];
    for (var key in keys) {
      out.addAll(_cache[key]);
    }
    return out;
  }

  void clear() => _cache.clear();
}

class DateCache extends TermCache {
  /// Loader function that gets the (expensive) data associated with an
  /// interval.  Data is further split using the [keyAssign] function and
  /// stored into the cache.
  @override
  Future<List<Map<String, dynamic>>> Function(Interval) loader;

  /// Function to partition the data returned by the [loader] into keys for
  /// storing into the cache.  Usually this function returns a Date or a Month
  /// object. e.g. keyAssign = (e) => e['date'] as Date;
  @override
  Interval Function(Map<String, dynamic>) keyAssign;

  /// A [TermCache] using [Date]s as keys.  Each key contains data as a
  /// [List<Map<String,dynamic>>]
  DateCache(this.loader, this.keyAssign)
      : super(
            loader,
            keyAssign,
            (Interval interval) =>
                interval.splitLeft((dt) => Date.fromTZDateTime(dt))) {
    /// check that the keyAssign return type is a Date??  Must be a better way
    // if (keyAssign.runtimeType.toString() != '(Map<String, dynamic>) => Date')
    //  throw ArgumentError('Incorrect signature for keyAssign');
  }
}

class MonthCache extends TermCache {
  /// Loader function that gets the (expensive) data associated with an
  /// interval.  Data is further split using the [keyAssign] function and
  /// stored into the cache.
  @override
  Future<List<Map<String, dynamic>>> Function(Interval) loader;

  /// Function to partition the data returned by the [loader] into keys for
  /// storing into the cache.  Usually this function returns a Date or a Month
  /// object. e.g. keyAssign = (e) => e['date'] as Date;
  @override
  Interval Function(Map<String, dynamic>) keyAssign;

  /// A [TermCache] using [Month]s as keys.
  MonthCache(this.loader, this.keyAssign)
      : super(
            loader,
            keyAssign,
            (Interval interval) =>
                interval.splitLeft((dt) => Month.fromTZDateTime(dt)));
}
