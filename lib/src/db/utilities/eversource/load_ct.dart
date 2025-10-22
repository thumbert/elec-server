import 'dart:async';
import 'dart:io';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:tuple/tuple.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

import 'package:elec_server/src/utils/iso_timestamp.dart';

import 'package:elec_server/src/db/config.dart';

class EversourceCtLoadArchive {
  late ComponentConfig dbConfig;
  late SpreadsheetDecoder _decoder;
  String? dir;
  Location location = getLocation('America/New_York');

  EversourceCtLoadArchive({ComponentConfig? dbConfig, this.dir}) {
    var env = Platform.environment;
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1', dbName: 'eversource', collectionName: 'load_ct');
    }
    dir ??= '${env['HOME']!}/Downloads/Archive/Utility/Eversource/CT/load/Raw/';

    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }
  }

  /// insert data into mongo
  Future insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    // split the data by day and version
    var groups = groupBy(
        data, (Map e) => Tuple2<String?, String?>(e['date'], e['version']));
    try {
      for (var key in groups.keys) {
        await dbConfig.coll.remove({
          'date': key.item1,
          'version': key.item2,
        });
        await dbConfig.coll.insertAll(groups[key]!);
      }
      print(
          '---> Inserted Eversource CT load data from ${data.first['date']} to ${data.last['date']}');
    } catch (e) {
      print('XXX $e');
    }
  }

  /// Check if the data has already been inserted
  Future<bool> hasDay(Date date, String version) async {
    var res = await dbConfig.coll.findOne({
      'date': date.toString(),
      'version': version,
    });
    if (res == null || res.isEmpty) return false;
    return true;
  }

  /// Read the entire contents of a given spreadsheet, and prepare it for
  /// Mongo insertion.
  List<Map<String, dynamic>> readXlsx(File file) {
    var bytes = file.readAsBytesSync();
    _decoder = SpreadsheetDecoder.decodeBytes(bytes);
    var sheetNames = _decoder.tables.keys;
    if (sheetNames.length != 1) {
      throw ArgumentError(
          'File format changed ${file.path}.  Only one sheet expected.');
    }

    var table = _decoder.tables[sheetNames.first]!;
    var n = table.rows.length;
    var res = <Map<String, dynamic>>[];

    var loadKeys = <String>[
      'LRS',
      'L-CI',
      'RES',
      'S-CI',
      'S-LT',
      'SS Total',
      'Competitive Supply',
    ];
    var keys = <String>[
      'date',
      'version',
      'hourBeginning',
      ...loadKeys,
    ];

    /// TODO: Check that the column names haven't changed
    // var actualNames =
    //     [2, 3, 4, 5, 6, 7, 8].map((i) => table.rows[3][i]).toList();

    for (int i = 4; i < n; i++) {
      var row = table.rows[i];
      if (row[0] != null) {
        var date = Date.parse((row[0] as String).substring(0, 10));
        String? hE;
        if (row[1] is int) {
          hE = row[1].toString().padLeft(2, '0');
        } else if (row[1] == '2*') {
          hE = '02X';
        } else {
          if (date == Date.utc(2018, 3, 11)) continue;
          throw ArgumentError('Unknown hour ending ${row[1]}');
        }
        var _hourBeginning = parseHourEndingStamp(mmddyyyy(date), hE);
        var hourBeginning = TZDateTime.fromMillisecondsSinceEpoch(
                location, _hourBeginning.millisecondsSinceEpoch)
            .toIso8601String();

        /// in case there are empty rows at the end of the spreadsheet
        res.add(Map.fromIterables(keys, [
          date.toString(),
          row[13],
          hourBeginning,
          row[2],
          row[3],
          row[4],
          row[5],
          row[6],
          row[7],
          row[8],
        ]));
      }
    }

    /// group by date
    Map<String?, List<Map>> aux = groupBy(res, (Map row) => row['date']);
    var data = <Map<String, dynamic>>[];
    for (var date in aux.keys) {
      var bux = aux[date]!;
      var hB = [];
      var load = [];
      for (var row in bux) {
        hB.add(row['hourBeginning']);
        load.add(Map.fromIterables(loadKeys, loadKeys.map((key) => row[key])));
      }
      data.add(<String, dynamic>{
        'date': date,
        'version': bux.first['version'],
        'hourBeginning': hB,
        'load': load,
      });
    }

    return data;
  }

  /// Get the file for this month
  File getFile(int? year) {
    return File('${dir!}actual_load_${year.toString()}.xlsx');
  }

  /// Download a file.
  /// https://www.eversource.com/content/ct-c/about/about-us/doing-business-with-us/energy-supplier-information/wholesale-supply-(connecticut)
  /// https://www.eversource.com/content/docs/default-source/doing-business/actual-load-2016.xlsx?sfvrsn=e5a7fb62_6
  Future downloadFile(String link) async {
    var url = 'https://www.eversource.com$link';
    var year = getYear(link);
    var fileout = getFile(year);
    return HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));
  }

  Future<void> setup() async {
    await dbConfig.db.open();
    List<String?> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName)) {
      await dbConfig.coll.drop();
    }
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1, 'version': 1}, unique: true);

    await dbConfig.db.close();
  }
}

/// Extract the year from the url link
//  var links = [
//    '/content/docs/default-source/doing-business/actual-load-2014.xlsx?sfvrsn=516bec62_8',
//    '/content/docs/default-source/doing-business/actual-load-2015.xlsx?sfvrsn=4c6bec62_26',
//    '/content/docs/default-source/doing-business/actual-load-2016.xlsx?sfvrsn=e5a7fb62_6',
//    '/content/docs/default-source/doing-business/actual-loads-2017.xlsx?sfvrsn=5b44c762_10',
//    '/content/docs/default-source/doing-business/actual-loads-2018-n.xlsx?sfvrsn=fedccc62_4',
//    '/content/docs/default-source/doing-business/actual-loads-2019-n.xlsx?sfvrsn=18b3cb62_2'
//  ];
int getYear(String link) {
  var reg = RegExp('(.*)actual-load(.*).xlsx(.*)');
  var matches = reg.allMatches(link);
  var match = matches.elementAt(0);
  var aux = match.group(2)!;

  var reg2 = RegExp(r'(\d{4})');
  var e = reg2.allMatches(aux).elementAt(0);
  var year = e.group(0)!;
  return int.parse(year);
}

/// Get all the API links from url with a given pattern
Future<List<String>> getLinks(String url, {List<Pattern>? patterns}) async {
  var aux = await http.get(Uri.parse(url));
  var body = aux.body;
  var document = parse(body);
  var links = <String>[];

  // try one of these file patterns
  patterns ??= ['actual-load-', 'actual-loads-'];
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
