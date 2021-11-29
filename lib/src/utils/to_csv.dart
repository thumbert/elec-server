library utils.to_csv;

import 'package:csv/csv.dart';
import 'package:dama/basic/null_policy.dart';

String _nullToEmpty(dynamic x) {
  if (x == null) return '';
  return x.toString();
}

/// Write a list of maps to CSV.   Usually, the keys of the map are strings.
///
/// If [columnNames] are not specified, return all the available columns.
/// The default [nullPolicy] is to convert the nulls to empty strings
///
String listOfMapToCsv(List<Map> x,
    {List<String>? columnNames, String Function(dynamic)? nullPolicy}) {
  nullPolicy ??= _nullToEmpty;

  if (columnNames == null) {
    var _cNames = <String>{};
    for (var row in x) {
      _cNames.addAll(row.keys.map((e) => e.toString()));
    }
    columnNames = _cNames.toList();
  }

  var aux = <List>[];
  aux.add(columnNames);
  for (var row in x) {
    var sRow = [];
    for (var columnName in columnNames) {
      if (row.containsKey(columnName)) {
        var value = row[columnName];
        value ??= nullPolicy(value);
        sRow.add(value);
      } else {
        sRow.add('');
      }
    }
    aux.add(sRow);
  }
  return const ListToCsvConverter().convert(aux);
}

/// Write a map to CSV. Return a two column csv table, first column are the
/// keys, second column are the values.
String mapToCsv(Map x,
    {List<String>? columnNames, String Function(dynamic)? nullPolicy}) {
  var aux = <List>[];
  if (columnNames != null) aux.add(columnNames);
  x.forEach((k, v) {
    if (v is Iterable) {
      aux.add([k, ...v]);
    } else {
      aux.add([k, v]);
    }
  });
  return const ListToCsvConverter().convert(aux);
}
