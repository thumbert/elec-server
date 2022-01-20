library db.isone_ptids;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';

class PtidArchive {
  late ComponentConfig dbConfig;
  late String dir;

  PtidArchive({ComponentConfig? config, String? dir}) {
    Map env = Platform.environment;
    config ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'pnode_table');
    dbConfig = config;
    dir ??= env['HOME']! + '/Downloads/Archive/PnodeTable/Raw/';
    this.dir = dir!;
  }

  Db get db => dbConfig.db;

  /// Insert one xlsx file into the collection.
  /// [file] points to the downloaded xlsx file.  NOTE that you have to convert
  /// the file to xlsx by hand (for now).
  Future insertMongo(File file) {
    var data = readXlsx(file);
    return dbConfig.coll
        .insertAll(data)
        .then(
            (_) => print('--->  SUCCESS inserting ${path.basename(file.path)}'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /// Read an XLSX file.  Note that ISO files are xls, so you will need to
  /// convert it by hand for now.
  /// filename should look like this: 'pnode_table_2017_08_03.xlsx'
  List<Map<String, dynamic>> readXlsx(File file, {String? asOfDate}) {
    var filename = path.basename(file.path);
    if (path.extension(filename).toLowerCase() != '.xlsx') {
      throw 'Filename needs to be in the xlsx format';
    }

    asOfDate ??= _getAsOfDate(filename);

    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    List<Map<String, Object?>> res;

    if (Date.parse(asOfDate).isBefore(Date.utc(2018, 6, 7))) {
      res = _readXlsxVersion1(decoder);
    } else {
      /// current format
      res = _readXlsxVersion2(decoder);
    }

    /// add the asOfDate (as a String) to all rows
    return res.map((e) {
      e['asOfDate'] = asOfDate;
      return e;
    }).toList();
  }

  /// prior to 2018-06-07 the spreadsheet had only one sheet
  List<Map<String, Object?>> _readXlsxVersion1(SpreadsheetDecoder decoder) {
    var res = <Map<String, Object?>>[];
    var table = decoder.tables['New England']!;

    /// the 2rd row is the Hub
    res.add({
      'ptid': 4000,
      'name': table.rows[2][2],
      'spokenName': 'HUB',
      'type': 'hub'
    });

    /// rows 4:11 are the Zones
    for (var r = 4; r < 12; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
        'type': 'zone'
      });
    }

    /// rows 13:16 are Reserve Zones
    for (var r = 13; r < 17; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][0],
        'type': 'reserve zone',
      });
    }

    /// rows 18:23 are Interfaces
    for (var r = 18; r < 24; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
      });
    }

    /// rows 26:end are simple nodes
    var nRows = table.rows.length;
    for (var r = 26; r < nRows; r++) {
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
    return res;
  }

  /// after 2018-06-07 the format changed to 2 sheets
  List<Map<String, Object?>> _readXlsxVersion2(SpreadsheetDecoder decoder) {
    var res = <Map<String, Object?>>[];
    var table = decoder.tables['Zone Information']!;

    /// the 2rd row is the Hub
    res.add({
      'ptid': 4000,
      'name': table.rows[2][2],
      'spokenName': 'HUB',
      'type': 'hub'
    });

    /// rows 5:12 are the Zones
    for (var r = 5; r < 13; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
        'type': 'zone'
      });
    }

    /// rows 15:18 are Reserve Zones
    for (var r = 15; r < 19; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][0],
        'type': 'reserve zone',
      });
    }

    /// rows 21:26 are Interfaces
    for (var r = 21; r < 27; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
      });
    }

    /// rows 8:26 are the DRR aggregation zones
    for (var r = 7; r < 27; r++) {
      res.add({
        'ptid': table.rows[r][7],
        'name': table.rows[r][6],
        'spokenName': table.rows[r][5],
        'type': 'demand response zone'
      });
    }

    /// Second tab
    /// rows 26:end are simple nodes
    table = decoder.tables['New England']!;
    var nRows = table.rows.length;
    for (var r = 2; r < nRows; r++) {
      // sometimes the spreadsheet has empty rows
      if (table.rows[r][5] != null) {
        var aux = {
          'ptid': table.rows[r][5],
          'name': table.rows[r][4],
          'spokenName': table.rows[r][0],
          'substationName': table.rows[r][1],
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
    var regExp = RegExp(r'pnode_table_(\d{4})_(\d{2})_(\d{2})\.xlsx');
    var matches = regExp.allMatches(filename);
    var match = matches.elementAt(0);
    if (match.groupCount != 3) {
      throw 'Can\'t parse the date from filename: $filename';
    }
    return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
  }

  /// Download a ptid file from the ISO.  Save it with the same name.
  Future downloadFile(String url) async {
    var filename = path.basename(url);
    var fileout = File(dir + filename);

    if (fileout.existsSync()) {
      print('File $filename is already downloaded.');
    }

    return HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));
  }

  /// Recreate the collection from scratch.
  /// Insert all the files in the archive directory.
  void setup() async {
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }

    await dbConfig.db.open();
    var collections = await dbConfig.db.getCollectionNames();
    print('Collections in db:');
    print(collections);
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();

    // this indexing assures that I don't insert the same data twice
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'asOfDate': 1, 'ptid': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'asOfDate': 1});
    await dbConfig.db.close();
  }
}
