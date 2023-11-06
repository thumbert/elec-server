library src.db.lib_settlements;

import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:table/table.dart';

enum SettlementType {
  firstSettlement,
  finalSettlement,
}

/// Get the nth settlement of some versioned data.
///
/// <p>[n] the settlement version.  n=0, is the first settlement. n=1, is the
/// second settlement, etc. The default [n=99] is the last settlement.
/// <p>[data] elements needs to contain a "version" key, usually a timestamp.
/// <p>[group] is a function that groups the input list [data] into unique
/// versions.  For example, ```group = (e) => e['hourBeginning']``` for one
/// group and ```group = (e) => Tuple2(e['ptid'], e['hourBeginning'])``` for
/// two groups.
///
///
List<Map<String, dynamic>> getNthSettlement(List<Map<String, dynamic>> data,
    dynamic Function(Map<String, dynamic>) group,
    {int n = 99}) {
  var nest = Nest()
    ..key((Map<String, dynamic> e) => group(e))
    ..rollup((List x) {
      /// always need to sort by version
      x.sort((a, b) => a['version'].compareTo(b['version']) as int);
      if (x.length <= n) return x.last;
      return x[n];
    });
  var out = (nest.map(data) as Map).values.toList();
  return out.cast<Map<String, dynamic>>();
}

/// Split all data into the different settlements.
/// <p>Return a list of settlements.
List<List<Map<String, dynamic>>> getAllSettlements(
    List<Map<String, dynamic>> data,
    dynamic Function(Map<String, dynamic>) group) {
  //data.sort((a, b) => a[group].compareTo(b[group]));
  var grp = groupBy(data, (Map<String, dynamic> e) => group(e));
  var maxSettlement = max(grp.values.map((e) => e.length)) as int;

  var out = List.generate(maxSettlement, (i) => <Map<String, dynamic>>[]);
  for (var entry in grp.entries) {
    var xs = entry.value
      ..sort((a, b) => a['version'].compareTo(b['version']) as int);
    for (var s = 0; s < maxSettlement; s++) {
      if (s < xs.length) {
        out[s].add(xs[s]);
      } else {
        out[s].add(xs.last);
      }
    }
  }

  return out;
}
