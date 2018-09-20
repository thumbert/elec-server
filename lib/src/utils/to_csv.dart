library utils.to_csv;

import 'package:csv/csv.dart';

/// Write a list of maps to CSV.  Column names are taken from the keys of
/// the first element of the list.  Usually, the keys of the map are strings.
String listOfMapToCsv(List<Map> x) {
  var aux = [];
  var colNames = x.first.keys.toList();
  aux.add(colNames);
  x.forEach((Map e){
    aux.add(e.values.toList());
  });
  return const ListToCsvConverter().convert(aux);
}

/// Write a map to CSV. Return a two column csv table, first column are the
/// keys, second column are the values.
String mapToCsv(Map x, {List<String> columnNames}) {
  var aux = [];
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
