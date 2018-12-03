library utils.to_csv;

import 'package:csv/csv.dart';

/// Write a list of maps to CSV.   Usually, the keys of the map are strings.
///
/// If [columnNames] are not specified, return all the available columns. 
String listOfMapToCsv(List<Map> x, {List<String> columnNames}) {
  if (columnNames == null) {
    var _cNames = Set<String>();
    for (var row in x) _cNames.addAll(row.keys.map((e) => e.toString()));
    columnNames = _cNames.toList();
  }

  var aux = <List>[];
  aux.add(columnNames);
  x.forEach((Map row) {
    var sRow = [];
    for (var columnName in columnNames) {
      if (row.containsKey(columnName)) {
        sRow.add(row[columnName]);
      } else {
        sRow.add('');
      }
    }
    aux.add(sRow);
  });
  return const ListToCsvConverter().convert(aux);
}


/// Write a map to CSV. Return a two column csv table, first column are the
/// keys, second column are the values.
String mapToCsv(Map x, {List<String> columnNames}) {
  var aux = <List>[];
  if (columnNames != null) aux.add(columnNames);
  x.forEach((k,v){
    if (v is Iterable) {
      aux.add([k]..addAll(v));
    } else {
      aux.add([k]..add(v));
    }
  });
  return const ListToCsvConverter().convert(aux);
}
