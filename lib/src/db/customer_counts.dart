library db.customer_counts;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';


class NGridCustomerCountsArchive {
  ComponentConfig config;

  NGridCustomerCountsArchive({this.config}) {
    if (config == null) {
      Map env = Platform.environment;
      config = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isone'
        ..collectionName = 'ngrid_customer_counts'
        ..DIR = env['HOME'] + '/Downloads/Archive/CustomerCounts/NGrid/';
    }
  }

  Db get db => config.db;


  /// Read the entire contents of a given spreadsheet, and prepare it for
  /// Mongo insertion.
  List<Map> readXlsx(File file) {
    List<Map> res = [];
    var bytes = file.readAsBytesSync();
    var decoder = new SpreadsheetDecoder.decodeBytes(bytes);

    List sheetNames = ['SEMA', 'NEMA', 'WCMA', 'SEMA & WCMA', 'NEMA & WCMA'];
    for (var sheet in sheetNames) {
      var table = decoder.tables[sheet];
      res.addAll( _readSheet(table) );
    }

    return res;
  }

  /// read one sheet at a time
  List<Map> _readSheet(SpreadsheetTable table) {
    /// the first row is the months

  }


  /// Get the most recent file in the archive folder
  File getLatestFile() {
    Directory directory = new Directory(config.DIR);
    var files = directory.listSync().where((f) => path.extension(f.path).toLowerCase() == '.xlsx').toList();
    files.sort((a,b)=>a.path.compareTo(b.path));
    return files.last;
  }

  /// Download a file.  Append the date to the filename.
  /// https://www9.nationalgridus.com/energysupply/current/20170811/Monthly_Aggregation_customer%20count%20and%20usage.xlsx
  ///
  Future downloadFile(String url) async {
    RegExp regExp = new RegExp(r'(.*)/current/(\d{8})/Monthly(.*)');
    var matches = regExp.allMatches(url);
    var match = matches.elementAt(0);

    String filename = path.basename(url);
    File fileout = new File(config.DIR + match.group(2) + '_' + filename);
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



}