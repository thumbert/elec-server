library db.isone_ptids;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';

class PtidArchive {
  ComponentConfig config;

  PtidArchive({this.config}) {
    Map env = Platform.environment;
    if (config == null) {
      config = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isone'
        ..collectionName = 'pnode_table'
        ..DIR = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';
    }
  }

  Db get db => config.db;

  /// Insert one xlsx file into the collection.
  /// [file] points to the downloaded xlsx file.  NOTE that you have to convert
  /// the file to xlsx by hand (for now).
  Future insertMongo(File file) {
    String date = _getAsOfDate(path.basename(file.path));
    List<Map> data = readXlsx(file);
    print('Inserting day $date into db');
    return config.coll
        .insertAll(data)
        .then((_) => print('--->  SUCCESS'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /// Read an XLSX file.  Note that ISO files are xls, so you will need to
  /// convert it by hand for now.
  /// filename should look like this: 'pnode_table_2017_08_03.xlsx'
  List<Map> readXlsx(File file, {String asOfDate}) {
    String filename = path.basename(file.path);
    if (path.extension(filename).toLowerCase() != '.xlsx')
      throw 'Filename needs to be in the xlsx format';

    asOfDate ??= _getAsOfDate(filename);

    List<Map> res = [];
    var bytes = file.readAsBytesSync();
    var decoder = new SpreadsheetDecoder.decodeBytes(bytes);
    var table = decoder.tables['New England'];

    /// the 2rd row is the Hub
    res.add({
      'ptid': 4000,
      'name': table.rows[2][2],
      'spokenName': 'HUB',
    });

    /// rows 4:11 are the Zones
    for (int r=4; r<12; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
      });
    }

    /// rows 13:16 are Reserve Zones
    for (int r=13; r<16; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
      });
    }

    /// rows 18:23 are Interfaces
    for (int r=18; r<23; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
      });
    }

    /// rows 26:end are simple nodes
    int nRows = table.rows.length;
    for (int r=26; r<nRows; r++) {
      // sometimes the spreadsheet has empty rows
      if (table.rows[r][5] != null) {
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

    /// add the asOfDate (as a String) to all rows
    return res.map((Map e) {
      e['asOfDate'] = asOfDate;
      return e;
    }).toList();
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
    File fileout = new File(config.DIR + filename);

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
  setup() async {
    if (!new Directory(config.DIR).existsSync()) new Directory(config.DIR)
        .createSync(recursive: true);
    String fname = 'pnode_table_2017_08_03.xls';
    String url = 'https://www.iso-ne.com/static-assets/documents/2017/08/$fname';
    //await downloadFile(url);

    await config.db.open();
    List<String> collections = await config.db.getCollectionNames();
    print('Collections in db:');
    print(collections);
    if (collections.contains(config.collectionName)) await config.coll.drop();

    // insert all xlsx files in the Raw/ directory
    Directory directory = new Directory(config.DIR);
    var files = directory.listSync().where((f) => path.extension(f.path).toLowerCase() == '.xlsx').toList();
    for (var file in files) {
      await insertMongo(file);
    }

    // this indexing assures that I don't insert the same data twice
    await config.db.createIndex(config.collectionName,
        keys: {'asOfDate': 1, 'ptid': 1}, unique: true);
    await config.db.createIndex(config.collectionName, keys: {'asOfDate': 1});

    await config.db.close();
  }

}

