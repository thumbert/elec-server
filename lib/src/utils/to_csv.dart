library utils.to_csv;

import 'package:csv/csv.dart';

/// Write a list of maps to CSV.  Column names are taken from the keys of
/// the first element of the list.  Usually, the keys of the map are strings.
String listOfMapToCsv(List<Map> x) {
  var aux = [];
  var colnames = x.first.keys.toList();
  aux.add(colnames);
  x.forEach((Map e){
    aux.add(e.values.toList());
  });
  return const ListToCsvConverter().convert(aux);
}

/// Write a map to CSV.
String mapToCsv(Map x, {List<String> colnames}) {
  var aux = [];
  if (colnames != null) aux.add(colnames);
  x.forEach((k,v){
    if (v is Iterable) {
      aux.add([k]..addAll(v));
    } else {
      aux.add([k]..add(v));
    }
  });
  return const ListToCsvConverter().convert(aux);
}
