library elec_server.client.dacongestion.v1;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

class DaCongestion {
  final String rootUrl;
  final Iso iso;
  final location = getLocation('America/New_York');

  /// Get congestion prices for all the nodes in the pool at once.
  DaCongestion(http.Client client,
      {required this.iso, this.rootUrl = 'http://localhost:8000'}) {
    if (!_isoMap.keys.contains(iso)) {
      throw ArgumentError('Iso $iso is not supported');
    }
  }

  final _isoMap = <Iso, String>{
    Iso.newEngland: '/isone',
    Iso.newYork: '/nyiso',
  };

  /// Date -> ptid -> hourly congestion prices for the day
  /// Always insert entire months at once, so the domain should be contiguous
  /// by construction.  Needs to be a SplayTreeMap so the concept of
  /// first/last key exists.
  final cache = SplayTreeMap<Date, Map<int, List<num>>>();

  /// Get hourly congestion prices between a start and end date for all the
  /// nodes in the pool. Inputs [start] and [end] should be UTC Dates.
  /// Return a [List] with elements in shape:
  /// ```dart
  /// {
  ///   'x': <TZDateTime>[...],  // hour beginning
  ///   'y': <num>[...],  // values
  ///   'ptid': <int>
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getHourlyTraces(Date start, Date end,
      {List<int>? ptids}) async {
    if (start.isAfter(end)) {
      throw ArgumentError('Invalid inputs: start is AFTER end');
    }
    await _populateCache(start, end);

    /// the cache should now have all the days you requested
    /// need to loop over all the days in range and then for all ptids
    var aux = <int, Map<String, dynamic>>{};
    var days = Term(start, end).days();
    for (var day in days) {
      if (cache.containsKey(day)) {
        var data = cache[day];
        var hours = day
            .withTimeZone(location)
            .splitLeft((dt) => Hour.beginning(dt))
            .map((e) => e.start.toIso8601String());
        var ptids = data!.keys.toList();
        for (var i = 0; i < ptids.length; ++i) {
          var ptid = ptids[i];
          if (!aux.containsKey(ptid)) {
            aux[ptid] = {
              'x': [],
              'y': [],
              'ptid': ptid,
            };
          }
          (aux[ptid]!['x'] as List).addAll(hours);
          (aux[ptid]!['y'] as List).addAll(data[ptid]!);
        }
      }
    }
    return aux.values.toList();
  }

  /// Populate the cache if needed.  If the data is compressed, expand it.
  Future<void> _populateCache(Date start, Date end) async {
    var term = calculateStartEnd(start, end);
    if (term != null) {
      var _url = rootUrl +
          _isoMap[iso]! +
          '/dacongestion/v1' +
          '/start/${term.startDate.toString()}/end/${term.endDate.toString()}';
      var _response = await http.get(Uri.parse(_url));
      var xs = json.decode(_response.body) as List;
      bool flipSign = false;
      if (iso == Iso.newYork) flipSign = true;
      for (var x in xs) {
        // loop over days
        var date = Date.parse(x['date'], location: UTC);
        var ptids = (x['ptids'] as List).cast<int>();
        var one = Map.fromIterables(
            ptids,
            List.generate(ptids.length,
                (index) => <num>[])); // keep all 24 hours of congestion
        var congestion = x['congestion'] as List;
        for (var data1H in congestion) {
          // data1H has data for 1 hour for all the nodes in the pool
          var aux = _rld(data1H);
          for (var i = 0; i < ptids.length; i++) {
            // loop over ptids
            if (flipSign) {
              one[ptids[i]]!.add(-aux[i]);
            } else {
              one[ptids[i]]!.add(aux[i]);
            }
          }
        }
        cache[date] = one;
      }
    }
  }

  /// Calculate the extend of the data you need.  If it returns [null] you
  /// need no new data.
  Term? calculateStartEnd(Date start, Date end) {
    start = Date.utc(start.year, start.month, 1);
    var lastMonth = Month.utc(end.year, end.month);
    end = lastMonth.endDate;

    /// NO CACHING --- things can get too big if you request Jan19 and then
    /// Oct21, you end up with all the nodes for several years.  Too much
    /// memory consumption.  So only pull one month at a time.
    // if (cache.isNotEmpty) {
    //   if (start.isBefore(cache.firstKey()!)) {
    //     start = Date.utc(start.year, start.month, 1);
    //     if (end.isBefore(cache.lastKey()!) || end == cache.lastKey()) {
    //       end = cache.firstKey()!.previous;
    //     }
    //   }
    //   if (start.isAfter(cache.lastKey()!)) {
    //     start = cache.lastKey()!.next;
    //   }
    //   // the easiest case
    //   if (cache.containsKey(start) && cache.containsKey(lastMonth.startDate)) {
    //     return null;
    //   }
    // }
    return Term(start, end);
  }

  List<num> _rld(List xs) {
    var ys = <num>[];
    if (xs.isEmpty) return ys;
    for (var i = 0; i < xs.length; i = i + 2) {
      if (xs[i] == 1) {
        ys.add(xs[i + 1] as num);
      } else {
        ys.addAll(List.filled(xs[i] as int, xs[i + 1] as num));
      }
    }
    return ys;
  }
}
