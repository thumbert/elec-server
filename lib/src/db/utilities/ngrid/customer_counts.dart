library db.customer_counts;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';

class NGridCustomerCountsArchive {
  ComponentConfig dbConfig;
  SpreadsheetDecoder _decoder;
  String dir;

  NGridCustomerCountsArchive({this.dbConfig, this.dir}) {
    Map env = Platform.environment;
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isone'
        ..collectionName = 'ngrid_customer_counts';
    }
    if (dir == null)
      dir = env['HOME'] + '/Downloads/Archive/CustomerCounts/NGrid/';
  }

  Db get db => dbConfig.db;

  /// Insert one xlsx file into the collection.
  /// [file] points to the downloaded xlsx file.  NOTE that you have to convert
  /// the file to xlsx by hand (for now).
  Future insertMongo({File file}) {
    file ??= getLatestFile();
    List<Map> data = readXlsx(file);
    print('Inserting ${file.path} into db');
    return dbConfig.coll
        .insertAll(data)
        .then((_) => print('--->  SUCCESS'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /// Read the entire contents of a given spreadsheet, and prepare it for
  /// Mongo insertion.
  List<Map> readXlsx(File file) {
    List<Map> res = [];
    var bytes = file.readAsBytesSync();
    _decoder = new SpreadsheetDecoder.decodeBytes(bytes);

    List sheetNames = ['SEMA', 'NEMA', 'WCMA', 'SEMA & WCMA', 'NEMA & WCMA'];
//    List sheetNames = ['NEMA'];
    for (var sheet in sheetNames) {
      res.addAll(_readSheet(sheet));
    }

    return res;
  }

  /// read one sheet at a time
  List<Map> _readSheet(String sheet) {
    int nRowsTown = 52;

    List<Map> res = [];
    var table = _decoder.tables[sheet];

    /// the first row is the months, starts in column 3
    List<Date> months = table.rows[0]
        .sublist(2)
        .map((x) => new Date.fromTZDateTime(
            new TZDateTime.from(convertXlsxDateTime(x), UTC)))
        .where((Date d) => d != null)
        .toList();

    int nMonths = months.length;
    int nTowns = ((table.rows.length - 1) / nRowsTown).round();
    print('number of towns for $sheet: $nTowns');

    for (int iTown = 0; iTown < nTowns; iTown++) {
      int startIdx = iTown * nRowsTown;
      var townName = table.rows[startIdx + 1][0];
      var header = {
        'zone': sheet,
        'town': townName,
      };

      /// get the customer counts on utility service, relative rows 5:11
      for (int r = 6; r <= 12; r++) {
        var aux = new Map.from(header);
        aux['rateClass'] = table.rows[startIdx + r][1];
        for (int m = 0; m < nMonths; m++) {
          if (table.rows[startIdx + r][m + 2] != null) {
            aux['provider'] = 'utility';
            aux['month'] = months[m].toString();
            aux['variable'] = 'customer counts';
            aux['value'] = table.rows[startIdx + r][m + 2];
            res.add(new Map.from(aux));
          }
        }
      }

      /// get the customer counts on utility service, relative rows 17:23
      for (int r = 18; r <= 24; r++) {
        var aux = new Map.from(header);
        aux['rateClass'] = table.rows[startIdx + r][1];
        for (int m = 0; m < nMonths; m++) {
          if (table.rows[startIdx + r][m + 2] != null) {
            aux['provider'] = 'utility';
            aux['month'] = months[m].toString();
            aux['variable'] = 'kWh';
            aux['value'] = table.rows[startIdx + r][m + 2];
            res.add(new Map.from(aux));
          }
        }
      }

      /// get the customer counts on competitive supply, relative rows 31:37
      for (int r = 31; r <= 37; r++) {
        var aux = new Map.from(header);
        aux['rateClass'] = table.rows[startIdx + r][1];
        for (int m = 0; m < nMonths; m++) {
          if (table.rows[startIdx + r][m + 2] != null) {
            aux['provider'] = 'competitive supply';
            aux['month'] = months[m].toString();
            aux['variable'] = 'customer counts';
            aux['value'] = table.rows[startIdx + r][m + 2];
            res.add(new Map.from(aux));
          }
        }
      }

      /// get the customer counts on utility service, relative rows 44:49
      for (int r = 43; r <= 49; r++) {
        var aux = new Map.from(header);
        aux['rateClass'] = table.rows[startIdx + r][1];
        for (int m = 0; m < nMonths; m++) {
          if (table.rows[startIdx + r][m + 2] != null) {
            aux['provider'] = 'competitive supply';
            aux['month'] = months[m].toString();
            aux['variable'] = 'kWh';
            aux['value'] = table.rows[startIdx + r][m + 2];
            res.add(new Map.from(aux));
          }
        }
      }
    }
    //res.forEach(print);

    return res;
  }

  DateTime convertXlsxDateTime(num x) =>
      new DateTime.fromMillisecondsSinceEpoch(((x - 25569) * 86400000).round(),
          isUtc: true);

  /// Get the most recent file in the archive folder
  File getLatestFile() {
    Directory directory = new Directory(dir);
    var files = directory
        .listSync()
        .where((f) => path.extension(f.path).toLowerCase() == '.xlsx')
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files.last;
  }

  /// Download a file.  Append the date to the filename.
  /// https://www9.nationalgridus.com/energysupply/current/20170811/Monthly_Aggregation_customer%20count%20and%20usage.xlsx
  /// Append the date to the filename for versioning.
  Future downloadFile(String url) async {
    RegExp regExp = new RegExp(r'(.*)/current/(\d{8})/Monthly(.*)');
    var matches = regExp.allMatches(url);
    var match = matches.elementAt(0);

    String filename = path.basename(url);
    File fileout = new File(dir + match.group(2) + '_' + filename);
    print(fileout);

    if (fileout.existsSync()) {
      print("File $filename is already downloaded.");
    }

    return new HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));
  }

  Future<Null> setup() async {
    if (!new Directory(dir).existsSync())
      new Directory(dir).createSync(recursive: true);

    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    print('Collections in ${dbConfig.dbName} db:');
    print(collections);
    if (collections.contains(dbConfig.collectionName)) await dbConfig.coll.drop();
    await insertMongo(file: getLatestFile());
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'variable': 1, 'zone': 1, 'town': 1});
    await dbConfig.db.close();
  }
}
