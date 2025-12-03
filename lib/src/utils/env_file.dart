import 'dart:io';

class EnvFile {
  /// Manipulate a .env file programmatically.
  EnvFile(this.file);

  final File file;

  /// Remove a key if it is in the file.
  void removeKey(String key) {
    var contents = file.readAsLinesSync();

    int? index;
    var fileModified = false;
    for (var i = 0; i < contents.length; i++) {
      var row = contents[i];
      var aux = row.split('='); // key = value
      // the value can contain other = signs inside (for example from base64)
      if (aux.length > 1) {
        var rowKey = aux[0].trim();
        if (rowKey == key) {
          index = i;
          fileModified = true;
        }
      }
    }

    if (index != null) {
      contents.removeAt(index);
      fileModified = true;
    }

    if (fileModified) {
      /// write the file back
      file.writeAsStringSync(contents.join('\n'), flush: true);
    }
  }

  /// Update an .env file with a (key,value) pair.  If the key doesn't exist,
  /// append it to the file.  If the key exists, replace existing value with
  /// the new value.
  void updateKey(String key, String value) {
    var contents = file.readAsLinesSync();

    var keyExists = false;
    var fileModified = false;
    for (var i = 0; i < contents.length; i++) {
      var row = contents[i];
      var aux = row.split('='); // key = value
      // the value can contain other = signs inside (for example from base64)
      if (aux.length > 1) {
        var rowKey = aux[0].trim();
        if (rowKey == key) {
          // replace existing value with the new one
          contents[i] = '$key = $value';
          keyExists = true;
          fileModified = true;
        }
      }
    }

    if (!keyExists) {
      contents.add('$key = $value');
      fileModified = true;
    }

    if (fileModified) {
      /// write the file back
      file.writeAsStringSync(contents.join('\n'), flush: true);
    }
  }
}
