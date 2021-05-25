library utils.lib_pdf;

import 'dart:io';

enum LayoutMode { layout, simple, table, linePrinter, raw }

/// Read a pdf file using the xpdf tools (pdftotext utility).
///
Future<List<String>> readPdf(File file,
    {int? firstPage,
    int? lastPage,
    LayoutMode layoutMode = LayoutMode.simple,
    bool? raw,
    int? fixed,
    int? lineSpacing,
    bool? noDiagonalText,
    String? eol, // one of 'unix', 'dos', 'mac'
    bool? noPageBreaks,
    bool? byteOrderMarker,
    String? ownerPassword,
    String? userPassword,
    bool? quiet,
    File? fileout,
    required Directory pathTopdftotext}) async {
  var executable = '"${pathTopdftotext.path}pdftotext" "' + file.path + '"';

  var options = <String>[];
  switch (layoutMode) {
    case LayoutMode.layout:
      options.add('-table');
      break;
    case LayoutMode.simple:
      options.add('-simple');
      break;
    case LayoutMode.table:
      options.add('-table');
      break;
    case LayoutMode.linePrinter:
      options.add('-lineprinter');
      break;
    case LayoutMode.raw:
      options.add('-raw');
      break;
  }
  noPageBreaks ??= false;
  if (noPageBreaks) options.add('-nopgbrk');
  
  // TODO: deal with errors
  var process = await Process.start(executable, ['-']);
  var aux = await process.stdout.toList();
  var lines = aux.map((e) => String.fromCharCodes(e));
  //print(lines);

  return lines.toList();
}
