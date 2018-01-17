
import 'dart:io';
import 'package:path/path.dart';

/// Get the last file updated in the directory.  Does not follow links or
/// search recursively.  It can be slow ...
File latestFile(Directory dir) {
  List files = dir.listSync().where((entity) => entity is File).toList();
  files.sort((File a, File b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
  return files.last;
}

/// List all the files from a directory that contain a pattern in the filename. 
List<File> listFiles(Directory dir, {Pattern pattern}) {
  List files = dir.listSync()
      .where((entity) => entity is File)
      .where((entity) => basenameWithoutExtension((entity as File).path).contains(pattern))
      .map((e) => e as File)
      .toList();
  files.sort((File a, File b) => a.path.compareTo(b.path));
  return files;
}
