library db.isoexpress.scc_report;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';

class SccReportArchive {
  late ComponentConfig config;
  late String dir;

  SccReportArchive({ComponentConfig? config, String? dir}) {
    Map env = Platform.environment;
    if (config == null) {
      this.config = ComponentConfig(
          host: '127.0.0.1',
          dbName: 'isoexpress',
          collectionName: 'scc_report');
    }

    dir ??= env['HOME'] +
        '/Downloads/Archive/IsoExpress/OperationsReports/SeasonalClaimedCapability/Raw/';
    this.dir = dir!;
  }

  mongo.Db get db => config.db;

  /// Insert one xlsx file into the collection.
  /// [file] points to the downloaded xlsx file.  NOTE that you have to convert
  /// the file to xlsx by hand (for now).
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    var month = data.first['month'];
    await config.coll.remove({'month': month});
    return config.coll.insertAll(data).then((_) {
      print('--->  SUCCESS inserting SCC Report for $month');
      return 0;
    }).catchError((e) {
      print(' XXXXX $e');
      return -1;
    });
  }

  /// Read an XLSX file.  Note that ISO files are xls, so you will need to
  /// convert it by hand for now.
  ///
  List<Map<String, dynamic>> readXlsx(File file, Month month) {
    String filename = path.basename(file.path);
    if (path.extension(filename).toLowerCase() != '.xlsx') {
      throw 'Filename needs to be in the xlsx format';
    }

    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    late List<Map<String, Object?>> res;

    if (month.isBefore(Month.utc(2030, 12))) {
      res = _readXlsxVersion1(decoder, month);
    }

    /// add the asOfDate (as a String) to all rows
    return res.map((e) {
      e['month'] = month.toIso8601String();
      return e;
    }).toList();
  }

  List<Map<String, dynamic>> _readXlsxVersion1(
      SpreadsheetDecoder decoder, Month month) {
    if (!decoder.tables.containsKey('SCC_Report_Current')) {
      throw StateError(
          'Spreadsheet format has changed.  Can\'t find tab SCC_Report_Current');
    }
    var table = decoder.tables['SCC_Report_Current']!;
    var res = <Map<String, dynamic>>[];

    var yyyymm = Date.fromExcel(table.rows[0][8]).toString().substring(0, 7);
    if (yyyymm != month.toIso8601String()) {
      throw StateError('Month from filename doesn\'t match internal month');
    }

    // Summer and Winter SCC values have the same row names, need to distinguish
    // them.
    var rowNames = table.rows[1].cast<String>();
    var mustHaveColumns = <dynamic>{}..addAll(
        ['Asset ID', 'Generator Name', 'SCC (MW)', 'Fuel Type', 'Load Zone']);
    if (!rowNames.toSet().containsAll(mustHaveColumns)) {
      throw StateError('Column names of the report have changed too much!');
    }

    var indSummer = <dynamic>{}..addAll([19, 20, 21, 22, 23]);
    var indWinter = <dynamic>{}..addAll([24, 25, 26, 27, 28]);

    int nRows = table.rows.length;
    for (int r = 2; r < nRows; r++) {
      // sometimes the spreadsheet has empty rows
      if (table.rows[r][0] != null) {
        var aux = <String, dynamic>{};
        for (int i = 0; i < rowNames.length; i++) {
          if (table.rows[r][i] != null) {
            var name = rowNames[i];
            if (indSummer.contains(i)) name = 'Summer $name';
            if (indWinter.contains(i)) name = 'Winter $name';
            var value = table.rows[r][i];
            if (i == 23 || i == 28) {
              value = Date.fromExcel(value as int).toString();
            }
            aux[name] = value;
          }
        }
        res.add(aux);
      }
    }
    return res;
  }

  /// Download an SCC report xls file from the ISO.  Save it with the same
  /// name in the xlsx format.
  Future downloadFile(String url) async {
    var filename = path.basename(url);
    var fileout = File(dir + filename);

    if (fileout.existsSync()) {
      print("File $filename is already downloaded.");
    }

    return HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));
  }

  /// https://www.iso-ne.com/static-assets/documents/2022/08/scc_august_2022.xls
  String makeUrl(Month month) {
    return 'https://www.iso-ne.com/static-assets/documents/'
        '${month.year}/${month.month.toString().padLeft(2, '0')}'
        '/scc_${_name[month.month]}_${month.year}.xls';
  }

  /// Recreate the collection from scratch.
  /// Insert all the files in the archive directory.
  setup() async {
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }

    // this indexing assures that I don't insert the same data twice
    await config.db.createIndex(config.collectionName,
        keys: {'month': 1, 'Asset ID': 1}, unique: true);
    await config.db.createIndex(config.collectionName, keys: {'Asset ID': 1});
    await config.db.close();
  }
}

const _name = {
  1: 'january',
  2: 'february',
  3: 'march',
  4: 'april',
  5: 'may',
  6: 'june',
  7: 'july',
  8: 'august',
  9: 'september',
  10: 'october',
  11: 'november',
  12: 'december',
};
