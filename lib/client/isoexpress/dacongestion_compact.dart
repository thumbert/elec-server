library elec_server.client.dacongestion_compact.v1;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:dama/basic/rle.dart';

class DaCongestion {
  final String rootUrl;
  final location = getLocation('America/New_York');

  /// Get congestion prices for all the nodes in the pool at once.
  DaCongestion(http.Client client, {this.rootUrl = 'http://localhost:8000'});

  /// Date -> ptid -> congestion prices
  /// Always insert entire months at once, and the domain should be contiguous
  /// by construction.
  final cache = SplayTreeMap<Date, Map<int, List<num>>>();
  final keys = {0, 0.01, 0.02};

  /// Get hourly congestion prices between a start and end date for all the
  /// nodes in the pool. Inputs [start] and [end] should be UTC Dates.
  Future<List<Map<String, dynamic>>> getTraces(Date start, Date end,
      {List<int>? ptids}) async {
    if (start.isAfter(end)) {
      throw ArgumentError('Invalid inputs: start is AFTER end');
    }
    var term = _calculateStartEnd(start, end);
    if (term != null) {
      var _url = rootUrl +
          '/da_congestion_compact/v1'
              '/start/${term.startDate.toString()}/end/${term.endDate.toString()}';
      print(_url);
      var _response = await http.get(Uri.parse(_url));
      var xs = json.decode(_response.body) as List;
      for (var x in xs) {
        var date = Date.parse(x['date'], location: UTC);
        var one = <int, List<num>>{};
        var ptids = x['ptids'] as List;
        var congestion = x['congestion'] as List;
        for (var i = 0; i < ptids.length; i++) {
          one[ptids[i] as int] = (congestion[i] as List).cast<num>();
        }
        cache[date] = one;
      }
    }

    /// the cache should now have all the days you requested
    /// need to traverse it twice, once for the ptids, once for the days
    var aux = <int, Map<String, dynamic>>{};
    var days = Term(start, end).days();
    for (var day in days) {
      if (cache.containsKey(day)) {
        var data = cache[day];
        var hours = day
            .withTimeZone(location)
            .splitLeft((dt) => Hour.beginning(dt))
            .map((e) => e.start);
        var ptids = data!.keys.toList();
        for (var i = 0; i < ptids.length; ++i) {
          var ptid = ptids[i];
          if (!aux.containsKey(ptid)) {
            aux[ptid] = {
              'x': [],
              'y': [],
              'name': ptid,
            };
          }
          (aux[ptid]!['x'] as List).addAll(hours);
          (aux[ptid]!['y'] as List)
              .addAll(runLenghtDecode(data[ptid]!, keys: keys));
        }
      }
    }
    return aux.values.toList();
  }

  /// Calculate the extend of the data you need.  If it returns [null] you
  /// need no new data.
  Term? _calculateStartEnd(Date start, Date end) {
    start = Date.utc(start.year, start.month, 1);
    var lastMonth = Month.utc(end.year, end.month);
    end = lastMonth.endDate;
    if (cache.isNotEmpty) {
      if (start.isBefore(cache.firstKey()!)) {
        start = Date.utc(start.year, start.month, 1);
        if (end.isBefore(cache.lastKey()!) || end == cache.lastKey()) {
          end = cache.firstKey()!.previous;
        }
      }
      if (start.isAfter(cache.lastKey()!)) {
        start = cache.lastKey()!.next;
      }
      // the easiest case
      if (cache.containsKey(start) && cache.containsKey(lastMonth.startDate)) {
        return null;
      }
    }
    return Term(start, end);
  }
}
