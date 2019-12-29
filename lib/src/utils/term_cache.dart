library utils.term_cache;

import 'package:collection/collection.dart';
import 'package:date/date.dart';

class TermCache {
  /// Loader function that adds data to the cache.
  Future<List<Map<String,dynamic>>> Function(Interval) loader;
  /// Function to assign data to a key, usually a Date or a Month object.
  /// e.g. keyAssign = (e) => e['date'] as Date;
  Interval Function(Map<String,dynamic>) keyAssign;
  var _cache = <Interval,List<Map<String,dynamic>>>{};

  /// A cache in the style of pacakage:more/cache.dart that stores data
  /// associated with an interval.
  ///
  TermCache(this.loader, this.keyAssign) {

  }

  /// Domain of the cache (where the cache has values.)
  List<Interval> domain() {
    var days = _cache.keys.toList()..sort();
    return Interval.fuse(days);
  }

  /// Populate the cache for the given [interval].  Only the keys that are
  /// not in the cache are retrieved and inserted.
  Future<Null> set(Interval interval) async {
    var missingIntervals = interval.difference(domain());
    for (var missingInterval in missingIntervals) {
      var data = await loader(missingInterval);
      var grp = groupBy(data, keyAssign);
      for (var date in grp.keys) {
        _cache[date] = grp[date];
      }
    }
  }

  /// Get all the entries associated with this interval from the cache.
  /// Make sure you call [set] first.
  List<Map<String,dynamic>> get(Interval interval) {
    var days = interval.splitLeft((dt) => Date.fromTZDateTime(dt)).cast<Date>();
    var out = <Map<String,dynamic>>[];
    for (var day in days) {
      out.addAll(_cache[day]);
    }
    return out;
  }

  void clear() => _cache.clear();
}
