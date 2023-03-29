library db.utilities.eversource.customer_counts_ct;

import 'dart:async';
import 'dart:io';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';

class EversourceCtCustomerCountsArchive {
  late ComponentConfig dbConfig;
  late SpreadsheetDecoder _decoder;
  String? dir;

  EversourceCtCustomerCountsArchive({ComponentConfig? dbConfig, this.dir}) {
    var env = Platform.environment;
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1',
          dbName: 'utility',
          collectionName: 'eversource_customer_counts');
    }
    dir ??= '${env['HOME']!}/Downloads/Archive/CustomerCounts/Eversource/CT/';
    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }
  }

  mongo.Db? get db => dbConfig.db;

  /// insert data from one or multiple files
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    var month = data.first['month'];
    await dbConfig.coll.remove({'region': 'CT', 'month': month});
    try {
      await dbConfig.coll.insertAll(data);
    } catch (e) {
      print(' XXXX ' + e.toString());
      return Future.value(1);
    }
    print('--->  SUCCESS Eversource CT inserting month $month');
    return Future.value(0);
  }

  /// Read the entire contents of a given spreadsheet, and prepare it for
  /// Mongo insertion.
  List<Map<String, dynamic>> readXlsx(File file) {
    var bytes = file.readAsBytesSync();
    _decoder = SpreadsheetDecoder.decodeBytes(bytes);

    var table = _decoder.tables['Smry Load Customer']!;
    var res = [
      {
        'service': 'competitive',
        'rateClass': 'residential ss',
        'mwh': table.rows[10][1],
        'customers': table.rows[21][1],
      },
      {
        'service': 'default',
        'rateClass': 'residential ss',
        'mwh': table.rows[11][1],
        'customers': table.rows[22][1],
      },
      {
        'service': 'competitive',
        'rateClass': 'business ss',
        'mwh': table.rows[10][3],
        'customers': table.rows[21][3],
      },
      {
        'service': 'default',
        'rateClass': 'business ss',
        'mwh': table.rows[11][3],
        'customers': table.rows[22][3],
      },
      {
        'service': 'competitive',
        'rateClass': 'business lrs',
        'mwh': table.rows[10][5],
        'customers': table.rows[21][5],
      },
      {
        'service': 'default',
        'rateClass': 'business lrs',
        'mwh': table.rows[11][5],
        'customers': table.rows[22][5],
      },
    ];

    /// add the month, region too
    var month = parseMonth(path.basename(file.path));
    res = res.map((e) {
      return <String, dynamic>{'region': 'CT', 'month': month, 'zone': 'ct'}
        ..addAll(e);
    }).toList();

    return res;
  }

  /// Download a file
  /// https://www.eversource.com/content/ct-c/about/about-us/doing-business-with-us/energy-supplier-information/wholesale-supply-(connecticut)
  /// Go to PURA Dockets
  Future downloadFile(String url, {File? fileout}) async {
    fileout ??= File(dir! + getFilename(url));
    url = 'https://www.eversource.com' + url;

    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }

    return HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout!.openWrite()));
  }

  Future<void> setup() async {
    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }

    await dbConfig.db.open();
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'region': 1, 'month': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'zone': 1, 'month': 1, 'rateClass': 1});

    await dbConfig.db.close();
  }
}

class EversourceCtCompetitiveSupply {
  late ComponentConfig dbConfig;
  late SpreadsheetDecoder _decoder;
  String? dir;

  EversourceCtCompetitiveSupply({ComponentConfig? dbConfig, this.dir}) {
    var env = Platform.environment;
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1',
          dbName: 'eversource',
          collectionName: 'competitive_suppliers');
    }
    dir ??= env['HOME']! + '/Downloads/Archive/CustomerCounts/Eversource/CT/';
    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }
  }

  mongo.Db? get db => dbConfig.db;

  /// insert data from one or multiple files
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    var month = data.first['month'];
    await dbConfig.coll.remove({'region': 'CT', 'month': month});
    try {
      await dbConfig.coll.insertAll(data);
    } catch (e) {
      print(' XXXX ' + e.toString());
      return Future.value(1);
    }
    print('--->  SUCCESS Eversource CT competitive suppliers for month $month');
    return Future.value(0);
  }

  /// Read the entire contents of a given spreadsheet, and prepare it for
  /// Mongo insertion.
  List<Map<String, dynamic>> readXlsx(File file) {
    var bytes = file.readAsBytesSync();
    _decoder = SpreadsheetDecoder.decodeBytes(bytes);

    if (!_decoder.tables.containsKey('Suppliers')) {
      throw ArgumentError('No sheet Suppliers in $file');
    }
    var table = _decoder.tables['Suppliers']!;
    var res = <Map<String, dynamic>>[];
    for (var row in table.rows) {
      if (row[0] != null && row[0] is num) {
        res.add({
          'supplierName': row[1],
          'customerCountResidential': row[2],
          'customerCountBusiness': row[3],
        });
      }
    }

    /// add the month, region too
    var month = parseMonth(path.basename(file.path));
    res = res.map((e) {
      return <String, dynamic>{'region': 'CT', 'month': month}..addAll(e);
    }).toList();

    return res;
  }

  /// Download a file
  /// https://www.eversource.com/content/ct-c/about/about-us/doing-business-with-us/energy-supplier-information/wholesale-supply-(connecticut)
  Future downloadFile(String url, {File? fileout}) async {
    fileout ??= File(dir! + getFilename(url));
    url = 'https://www.eversource.com' + url;

    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }

    return HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout!.openWrite()));
  }

  Future<void> setup() async {
    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }
    await dbConfig.db.open();
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'region': 1, 'month': 1});
    await dbConfig.db.close();
  }
}

/// Get all the API links from url with a given pattern
Future<List<String>> getLinks(String url, {Pattern? pattern}) async {
  var aux = await http.get(Uri.parse(url));
  var body = aux.body;
  var document = parse(body);
  var links = <String>[];

  // try one of these file patterns
  var patterns = ['customer-report-', 'customer-count-report-'];
  for (var linkElement in document.querySelectorAll('a')) {
    var link = linkElement.attributes['href'];

    /// ignore the internal links and the applications
    if (link != null && !link.startsWith('http')) {
      for (var pattern in patterns) {
        if (link.contains(pattern)) {
          links.add(link);
          break;
        }
      }
    }
  }
  links.sort();
  return links;
}

/// just the basename of the file, e.g. customer-count-report-december-2018.xlsx
String getFilename(String link) {
  var aux = path.basename(link);
  var bux = aux.split('?');
  return bux.first;
}

/// Get the month from the filename.  Return yyyy-mm format.
/// [filename] is the basename.
String parseMonth(String filename) {
  var aux = filename.replaceAll('customer-count-report-', '');
  aux = aux.replaceAll('customer-report-', '');
  if (aux == 'october-2019.xlsx') {
    return '2018-10';
  }

  var reg = RegExp('(.*).xlsx');
  var matches = reg.allMatches(aux);
  var match = matches.elementAt(0);
  var g1 = match.group(1)!;

  var bux = g1.split('-');
  // september is special!
  if (bux[0].toLowerCase() == 'sept') bux[0] = 'sep';
  var input = bux.take(2).join(' ');
  var parser = parseTerm(input.toUpperCase())!;
  return Month.fromTZDateTime(parser.start).toIso8601String();
}
