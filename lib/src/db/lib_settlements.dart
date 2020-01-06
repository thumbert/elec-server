library utils.lib_settlements;


import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:table/table.dart';


/// Get the nth settlement of some versioned data.  Most commonly used to
/// extract different settlements of RT Load data.  In that case input [data]
/// should be for one asset id only, or one ptid only!
///
/// <p>[n] the settlement version.  n=0, is the first settlement. n=1, is the
/// second settlement, etc. The default [n=99] is the last settlement.
/// <p>[data] elements needs to contain a "version" key, usually a time stamp.
/// <p>[group] is the time variable that has multiple versions
List<Map<String,dynamic>> getNthSettlement(List<Map<String,dynamic>> data,
    {int n=99, String group='hourBeginning'}) {
  var nest = Nest()
    ..key((Map<String,dynamic> e) => e[group])
    ..rollup((List x) {
      /// always need to sort by version
      x.sort((a, b) => a['version'].compareTo(b['version']));
      if (x.length <= n) return x.last;
      return x[n];
    });
  return nest.map(data).values.toList().cast<Map<String,dynamic>>();
}

/// Explore this idea where
/// group = (e) => Tuple2(e['product'], e['zoneId'])
List<Map<String,dynamic>> getNthSettlement2(List<Map<String,dynamic>> data,
    {int n=99, dynamic Function(Map<String,dynamic>) group}) {
  var nest = Nest()
    ..key((Map<String,dynamic> e) => group(e))
    ..rollup((List x) {
      /// always need to sort by version
      x.sort((a, b) => a['version'].compareTo(b['version']));
      if (x.length <= n) return x.last;
      return x[n];
    });
  return nest.map(data).values.toList().cast<Map<String,dynamic>>();
}



/// Split all data into the different settlements.  Input  [data]
/// should be for one asset id only, or one ptid only!
/// <p>Return a list of settlements.
List<List<Map<String,dynamic>>> getAllSettlements(List<Map<String,dynamic>> data,
  {String group='hourBeginning'}) {
  data.sort((a,b) => a[group].compareTo(b[group]));
  var grp = groupBy(data, (e) => e[group]);
  var maxSettlement = max(grp.values.map((e) => e.length));

  var out = List.generate(maxSettlement, (i) => <Map<String,dynamic>>[]);
  for (var entry in grp.entries) {
    var xs = entry.value..sort((a,b) => a['version'].compareTo(b['version']));
    for (var s=0; s<maxSettlement; s++) {
      if (s < xs.length) {
        out[s].add(xs[s]);
      } else {
        out[s].add(xs.last);
      }
    }
  }

  return out;
}


