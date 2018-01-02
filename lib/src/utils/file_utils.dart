
import 'dart:io';

/// Get the last file updated in the directory.  Does not follow links or
/// search recursively.  It can be slow ...
File latestFile(Directory dir) {
  List files = dir.listSync().where((entity) => entity is File).toList();
  files.sort((File a, File b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
  return files.last;
}
