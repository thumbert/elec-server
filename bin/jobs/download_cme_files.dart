import 'dart:io';

import 'package:elec_server/src/db/lib_prod_archives.dart' as prod;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart';

Future<int> main() async {
  var archive = prod.getCmeEnergySettlementsArchive();
  var res = await archive.downloadDataToFile();

  /// zip any txt files left in the directory
  var files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.txt'))
      .toList();
  for (var file in files) {
    var encoder = ZipFileEncoder();
    encoder.create('${archive.dir}${basenameWithoutExtension(file.path)}.zip');
    await encoder.addFile(file);
    encoder.close();
    file.deleteSync();
  }

  print('Exit code: $res');
  exit(res);
}
