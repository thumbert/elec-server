
import 'dart:io';
import 'package:path/path.dart';

/// Get the last file updated in the directory.  Does not follow links or
/// search recursively.  It can be slow ...
File latestFile(Directory dir) {
  var files = dir.listSync().whereType<File>().toList();
  files.sort((a,b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
  return files.last;
}

/// List all the files from a directory that contain a pattern in the filename. 
/// If the directory doesn't exist, return [];
List<File> listFiles(Directory dir, {Pattern? pattern}) {
  if (!dir.existsSync()) return [];
  var files = dir.listSync()
      .whereType<File>()
      .where((entity) => basenameWithoutExtension((entity).path).contains(pattern!))
      .where((e) => !e.path.endsWith('lnk'))
      .toList();
  files.sort((a,b) => a.path.compareTo(b.path));
  return files;
}
