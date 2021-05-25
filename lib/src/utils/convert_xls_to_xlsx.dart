import 'dart:io';

/// Convert an xls file to an xlsx file using Libre Office.
///
/// By default the output file  is the same as [fileIn] just with the extension
/// changed.
///
/// [dir] is the directory with the Libre Office installation if you need to
/// specify it (not on the path).
///
/// Note that this runs in the current directory.  You may want to change the
/// current directory before running this command.  
/// 
/// Return 0 if successful, 1 if a fail.
Future<int> convertXlsToXlsx(File fileIn, {Directory? pathToLibreOffice})
  async {
  String exec;
  if (Platform.isWindows) {
    exec = 'soffice';
  } else if (Platform.isLinux) {
    exec = 'libreoffice';
  } else {
    throw 'Unsuported platform ${Platform.operatingSystem}';
  }
  pathToLibreOffice ??= Directory('');
  var cmd = '"${pathToLibreOffice.path}$exec" --convert-to xlsx "' +
      fileIn.path + '" --headless';

  //print(cmd);
  var process = await Process.start(cmd, []);
  return process.exitCode;
}
