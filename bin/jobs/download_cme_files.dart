

import 'dart:io';

import 'package:elec_server/src/db/lib_prod_archives.dart' as prod;

Future<int> main() async {
  var archive = prod.getCmeEnergySettlementsArchive();
  var res = await archive.downloadDataToFile();
  print('Exit code: $res');
  exit(res);
}