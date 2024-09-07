import 'dart:io';

import 'package:logging/logging.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart' as prod;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart';

Future<int> main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  /// NOTE:  CME has started to charge for the data on 4/1/2024!
  ///
  var archive = prod.getCmeEnergySettlementsArchive();
  var res = await archive.downloadDataToFile();
  if (res == -1) {
    throw StateError('Download failed!');
  }

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

  /// insert the last 3 files
  files = Directory(archive.dir)
      .listSync()
      .whereType<File>()
      .where((e) => e.path.endsWith('.zip'))
      .toList();
  files.sort((a, b) => basename(a.path).compareTo(basename(b.path)));
  await archive.dbConfig.db.open();
  for (var file in files.reversed.take(3)) {
    // print('working on ${basename(file.path)}');
    var data = archive.processFile(file);
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();

  print('Exit code: $res');
  exit(res);
}
