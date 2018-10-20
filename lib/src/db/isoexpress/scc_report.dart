library db.isoexpress.scc_report;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';

class SccReportArchive {
  ComponentConfig config;
  String dir;

  SccReportArchive({this.config, this.dir}) {
    Map env = Platform.environment;
    if (config == null) {
      config = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isone'
        ..collectionName = 'scc_report';
    }
    dir ??= env['HOME'] + '/Downloads/Archive/IsoExpress/OperationsReports/SeasonalClaimedCapability/Raw/';
  }

  Db get db => config.db;

  /// Insert one xlsx file into the collection.
  /// [file] points to the downloaded xlsx file.  NOTE that you have to convert
  /// the file to xlsx by hand (for now).
  Future insertMongo(File file) {
    var data = readXlsx(file);
    return config.coll
        .insertAll(data)
        .then((_) => print('--->  SUCCESS inserting ${path.basename(file.path)}'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /// Read an XLSX file.  Note that ISO files are xls, so you will need to
  /// convert it by hand for now.
  ///
  List<Map<String,dynamic>> readXlsx(File file, Month month) {
    String filename = path.basename(file.path);
    if (path.extension(filename).toLowerCase() != '.xlsx')
      throw 'Filename needs to be in the xlsx format';

    var bytes = file.readAsBytesSync();
    var decoder = new SpreadsheetDecoder.decodeBytes(bytes);
    List<Map<String,Object>> res;

    res = _readXlsxVersion1(decoder);

    /// add the asOfDate (as a String) to all rows
    return res.map((e) {
      e['month'] = month.toIso8601String();
      return e;
    }).toList();
  }

  List<Map<String,Object>> _readXlsxVersion1(SpreadsheetDecoder decoder) {
    var res = <Map<String,Object>>[];
    var table = decoder.tables['SCC_Report_Current'];



    int nRows = table.rows.length;
    for (int r=2; r<nRows; r++) {
      // sometimes the spreadsheet has empty rows
      if (table.rows[r][0] != null) {
        var aux = {
          'ptid': table.rows[r][5],
          'name': table.rows[r][4],
          'spokenName': table.rows[r][0],
          'zonePtid': table.rows[r][6],
          'reservePtid': table.rows[r][7],
          'rspArea': table.rows[r][8],
          'dispatchZone': table.rows[r][9],
        };
        if (table.rows[r][2] != null) aux['unitName'] = table.rows[r][2];
        if (table.rows[r][3] != null) aux['unitShortName'] = table.rows[r][3];
        res.add(aux);
      }
    }
    return res;
  }




  /// Return the asOfDate in the yyyy-mm-dd format from the filename.
  /// Filename is usually just the basename, and in the form: 'pnode_table_2017_08_03.xlsx'
  String _getAsOfDate(String filename) {
    RegExp regExp = new RegExp(r'pnode_table_(\d{4})_(\d{2})_(\d{2})\.xlsx');
    var matches = regExp.allMatches(filename);
    var match = matches.elementAt(0);
    if (match.groupCount != 3)
      throw 'Can\'t parse the date from filename: $filename';
    return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
  }

  /// Download a ptid file from the ISO.  Save it with the same name.
  Future downloadFile(String url) async {
    String filename = path.basename(url);
    File fileout = new File(dir + filename);

    if (fileout.existsSync()) {
      print("File $filename is already downloaded.");
    }

    return new HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
        response.pipe(fileout.openWrite()));
  }


  /// Recreate the collection from scratch.
  /// Insert all the files in the archive directory.
  setup() async {
    if (!new Directory(dir).existsSync()) new Directory(dir)
        .createSync(recursive: true);

    await config.db.open();
    List<String> collections = await config.db.getCollectionNames();
    print('Collections in db:');
    print(collections);
    if (collections.contains(config.collectionName)) await config.coll.drop();

    // this indexing assures that I don't insert the same data twice
    await config.db.createIndex(config.collectionName,
        keys: {'month': 1, 'Asset ID': 1}, unique: true);
    await config.db.createIndex(config.collectionName, keys: {'Asset ID': 1});
    await config.db.close();
  }

}

