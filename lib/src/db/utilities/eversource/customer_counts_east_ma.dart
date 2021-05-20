library db.utilities.eversource.customer_counts_east_ma;

import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';


class EversourceEastMaCustomerCountsArchive {
  ComponentConfig dbConfig;
  String dir;

  EversourceEastMaCustomerCountsArchive({this.dbConfig, this.dir}) {
    Map env = Platform.environment;
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'utility'
        ..collectionName = 'eversource_customer_counts';
    }
    if (dir == null)
      dir =
          env['HOME'] + '/Downloads/Archive/CustomerCounts/Eversource/East_MA/';
    if (!Directory(dir).existsSync())
      Directory(dir).createSync(recursive: true);
  }

  mongo.Db get db => dbConfig.db;

  /// insert data from one or multiple files
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.length == 0) return Future.value(0);
    var month = data.first['month'];
    await dbConfig.coll.remove({'region': 'East MA', 'month': month});
    try {
      await dbConfig.coll.insertAll(data);
    } catch (e) {
      print(' XXXX ' + e.toString());
      return Future.value(1);
    }
    print('--->  SUCCESS Eversource East MA inserting month ${month}');
    return Future.value(0);
  }

  /// Read the entire contents of a given spreadsheet, and prepare it for
  /// Mongo insertion.
  List<Map<String, dynamic>> readXlsx(File file) {
    var month = parseMonth(path.basename(file.path));
    var bytes = file.readAsBytesSync();
    var _decoder = SpreadsheetDecoder.decodeBytes(bytes);

    var res = <Map<String, dynamic>>[];

    for (var sheet in _decoder.tables.keys) {
      var service;
      if (sheet.toLowerCase().contains('default')) {
        service = 'default';
      } else if (sheet.toLowerCase().contains('comp')) {
        service = 'competitive';
      }
      var zone;
      if (sheet.toLowerCase().contains('nema')) {
        zone = 'nema';
        if (sheet.toLowerCase().contains('primarily')) zone = 'primarily nema';
      } else if (sheet.toLowerCase().contains('sema')) {
        zone = 'sema';
        if (sheet.toLowerCase().contains('primarily')) zone = 'primarily sema';
      }

      var rows = _decoder.tables[sheet].rows;
      // 3 columns of data
      for (int i = 2; i < rows.length; i++) {
        if (rows[i][0] != null && rows[i][2] is num) {
          if (zone == null || service == null)
            throw 'Can\'t parse the zone and service type.';
          var aux = <String, dynamic>{
            'region': 'East MA',
            'month': month,
            'zone': zone,
            'service': service,
            'rateClass': rows[i][0].toString().replaceAll(RegExp('\\s'), '').toLowerCase(),
            'customers': rows[i][1],
            'mwh': rows[i][2]/1000,
          };
          res.add(aux);
        }
      }
    }

    return res;
  }

  /// Get the file for this month
  File getFile(Month month) {
    return File(dir + '${month.startDate.toString().substring(0, 7)}.xlsx');
  }

  /// Download a file.
  /// https://www.eversource.com/content/ct-c/about/about-us/doing-business-with-us/energy-supplier-information/wholesale-supply-(eastern-massachusetts)
  ///
  Future downloadFile(String url) async {
    var regExp = RegExp(r'(.*)/(customer-info-.*\.xls)\?(.*)');
    var matches = regExp.allMatches(url);
    var match = matches.elementAt(0);
    var fName = match.group(2);

    url = 'https://www.eversource.com' + url;

    if (!Directory(dir).existsSync())
      Directory(dir).createSync(recursive: true);

    var fileout = File(dir + fName);

    return new HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));
  }

  Future<Null> setup() async {
    if (!Directory(dir).existsSync())
      Directory(dir).createSync(recursive: true);

    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'region': 1, 'month': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'zone': 1, 'month': 1, 'service': 1});

    await dbConfig.db.close();
  }

}

/// Get all the API links from url with a given pattern
Future<List<String>> getLinks(String url, {Pattern pattern}) async {
  var aux = await http.get(Uri.parse(url));
  var body = aux.body;
  var document = parse(body);
  var links = <String>[];
  for (var linkElement in document.querySelectorAll('a')) {
    var link = linkElement.attributes['href'];

    /// ignore the internal links and the applications
    if (link != null && link.contains(pattern) && !link.startsWith('http')) {
      links.add(link);
    }
  }
  links.sort();
  return links;
}

///
String getFilename(String link) {
  var aux = path.basename(link);
  var bux = aux.split('?');
  return bux.first;
}

/// Get the month from the filename.
/// [filename] is the basename.
String parseMonth(String filename) {
  var reg = RegExp('customer-info-(.*).xlsx');
  var matches = reg.allMatches(filename);
  var match = matches.elementAt(0);
  var g1 = match.group(1);

  /// there may still be another '-(1)' at the end of the month, e.g.
  /// customer-info-november-2016-(1).xlsx
  var bux = g1.split('-');
  // september is special!
  if (bux[0].toLowerCase() == 'sept') bux[0] = 'sep';
  var input = bux.take(2).join(' ');
  var parser = parseTerm(input.toUpperCase());
  return Month.fromTZDateTime(parser.start).toIso8601String();
}
