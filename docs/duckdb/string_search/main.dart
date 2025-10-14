import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/ieso/ieso_client.dart';
import 'package:http/http.dart';

/// Make a list of strings from electricity locations
Future<void> makeList() async {
  final rootUrl = dotenv.env['ROOT_URL']!;
  final rustServer = dotenv.env['RUST_SERVER']!;

  var result = <String>[];

  // add IESO locations
  var ieso = IesoClient(Client(), rootUrl: rootUrl, rustServer: rustServer);
  var aux = await ieso.getNodeTable();
  for (var (type, name) in aux) {
    result.add('IESO:$type:$name:DA');
    result.add('IESO:$type:$name:RT');
  }

  // add ISONE locations
  var res = await get(Uri.parse('$rootUrl/ptids/v1/current'));
  var data = (res.body.isEmpty) ? [] : (json.decode(res.body) as List);
  for (var e in data) {
    var ptid = e['ptid'];
    var name = e['name'];
    result.add('ISONE:$name, ptid:$ptid:DA');
    result.add('ISONE:$name, ptid:$ptid:RT');
  }

  // add NYISO locations
  res = await get(Uri.parse('$rootUrl/nyiso/ptids/v1/current'));
  data = (res.body.isEmpty) ? [] : (json.decode(res.body) as List);
  for (var e in data) {
    var ptid = e['ptid'];
    var name = e['name'];
    result.add('NYISO:$name, ptid:$ptid:DA');
    result.add('NYISO:$name, ptid:$ptid:RT');
  }

  // add PJM locations
  res = await get(Uri.parse('$rootUrl/pjm/ptids/v1/current'));
  data = (res.body.isEmpty) ? [] : (json.decode(res.body) as List);
  for (var e in data) {
    var ptid = e['ptid'];
    var name = e['name'];
    result.add('PJM:$name, ptid:$ptid:DA');
    result.add('PJM:$name, ptid:$ptid:RT');
  }

  print('There are ${result.length} locations.');
  file.writeAsStringSync(result.join('\n'));
}

void dartSearch(String token, List<String> lines) {
  var stopwatch = Stopwatch()..start();
  var res = <String>[];
  for (var line in lines) {
    if (line.contains(token)) {
      res.add(line);
    }
  }
  stopwatch.stop();
  print('\nDart JIT found ${res.length} entries with "$token".  '
      'Search time: ${stopwatch.elapsedMilliseconds} ms');
  print(res.join('\n'));

}

void dartSpeed() {
  var lines = file.readAsLinesSync();
  dartSearch('4004', lines);
  dartSearch('BGE', lines);
}

final file = File('/home/adrian/Downloads/Archive/PnodeTable/locations.csv');

/// Investigate the speed of string search in Dart, DuckDB and Rust
void main() {
  dotenv.load('.env/prod.env');
  // makeList();

  dartSpeed();
}
