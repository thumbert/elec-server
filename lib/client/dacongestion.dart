import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

class DaCongestion {
  /// Get congestion prices for all the nodes in the pool at once.
  DaCongestion(http.Client client,
      {required this.iso,
      required this.rootUrl,
      required this.rustServer}) {
    if (!_isoMap.keys.contains(iso)) {
      throw ArgumentError('Iso $iso is not supported');
    }
  }

  final String rootUrl;
  final String rustServer;
  final Iso iso;
  final location = getLocation('America/New_York');

  final _isoMap = <Iso, String>{
    Iso.newEngland: '/isone',
    Iso.newYork: '/nyiso',
    Iso.ieso: '/ieso',
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

    /// The cache should now have all the days you requested.
    /// Loop over all the days in range and then for all ptids.
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

  /// Populate the cache.  As the data is in run-length compressed, expand it.
  Future<void> _populateCache(Date start, Date end) async {
    var term = calculateStartEnd(start, end);
    var url = '$rustServer${_isoMap[iso]!}/prices/da/hourly'
        '/start/${term.startDate.toString()}/end/${term.endDate.toString()}'
        '?components=mcc&format=compact';
    var response = await http.get(Uri.parse(url));
    var xs = json.decode(response.body) as Map;
    bool flipSign = false;
    if (iso == Iso.newYork) flipSign = true;
    for (var entry in xs.entries) {
      // loop over days
      var date = Date.parse(entry.key, location: UTC);
      var x = entry.value as Map<String, dynamic>;
      var one = Map<int, List<num>>.fromEntries(x.entries.map((e) => flipSign
          ? MapEntry(
              int.parse(e.key), e.value.cast<num>().map((v) => -v).toList())
          : MapEntry(int.parse(e.key), e.value.cast<num>())));
      cache[date] = one;
    }
  }

  /// Calculate the extend of the data you need.  Always round to full months.
  Term calculateStartEnd(Date start, Date end) {
    start = Date.utc(start.year, start.month, 1);
    var lastMonth = Month.utc(end.year, end.month);
    end = lastMonth.endDate;
    return Term(start, end);
  }
}
