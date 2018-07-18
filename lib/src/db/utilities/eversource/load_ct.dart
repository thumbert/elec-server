library db.utilities.eversource.load_ct;

import 'dart:async';
import 'dart:io';
import 'package:tuple/tuple.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

import 'package:elec_server/src/db/config.dart';

Map loadUrls = {
  2018: 'actual-loads-2018.xlsx?sfvrsn=d9fdc462_8',
  2017: 'actual-loads-2017.xlsx?sfvrsn=5b44c762_10',
  2016: 'actual-load-2016.xlsx?sfvrsn=e5a7fb62_6',
  2015: 'actual-load-2015.xlsx?sfvrsn=4c6bec62_26',
  2014: 'actual-load-2014.xlsx?sfvrsn=516bec62_8',
};

class EversourceCtLoadArchive {
  ComponentConfig dbConfig;
  SpreadsheetDecoder _decoder;
  String dir;
  Location location = getLocation('US/Eastern');

  EversourceCtLoadArchive({this.dbConfig, this.dir}) {
    Map env = Platform.environment;

    dbConfig ??= new ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'eversource'
      ..collectionName = 'load_ct';

    dir ??= env['HOME'] + '/Downloads/Archive/Utility/Eversource/CT/load/Raw/';

    if (!new Directory(dir).existsSync())
      new Directory(dir).createSync(recursive: true);
  }

  /// insert data into mongo
  Future insertData(List<Map> data) async {
    if (data.isEmpty) return new Future.value(null);
    // split the data by day and version
    Map groups = _groupBy(data, (Map e) => new Tuple2(e['date'], e['version']));
    try {
      for (Tuple2 key in groups.keys) {
        await dbConfig.coll.remove({
          'date': key.item1,
          'version': key.item2,
        });
        await dbConfig.coll.insertAll(groups[key]);
      }
      print('---> Inserted Eversource CT load data from ${data.first['date']} to ${data.last['date']}');
    } catch (e) {
      print('XXX ' + e.toString());
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
  List<Map> readXlsx(File file) {
    var bytes = file.readAsBytesSync();
    _decoder = new SpreadsheetDecoder.decodeBytes(bytes);
    var sheetNames = _decoder.tables.keys;
    if (sheetNames.length != 1)
      throw new ArgumentError(
          'File format changed ${file.path}.  Only one sheet expected.');

    var table = _decoder.tables[sheetNames.first];
    var n = table.rows.length;
    List<Map> res = [];

    List loadKeys = [
      'LRS',
      'L-CI',
      'RES',
      'S-CI',
      'S-LT',
      'SS Total',
      'Competitive Supply',
    ];
    List keys = [
      'date',
      'version',
      'hourBeginning',
    ]..addAll(loadKeys);

    /// TODO: Check that the column names haven't changed
    var actualNames =
        [2, 3, 4, 5, 6, 7, 8].map((i) => table.rows[3][i]).toList();

    for (int i = 4; i < n; i++) {
      List row = table.rows[i];
      if (row[0] != null) {
        Date date = Date.parse((row[0] as String).substring(0, 10));
        String hE;
        if (row[1] is int)
          hE = row[1].toString().padLeft(2, '0');
        else if (row[1] == '2*')
          hE = '02X';
        else
          throw new ArgumentError('Unknown hour ending ${row[1]}');
        TZDateTime hourBeginning = parseHourEndingStamp(mmddyyyy(date), hE);

        /// in case there are empty rows at the end of the spreadsheet
        res.add(new Map.fromIterables(keys, [
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
    var aux = _groupBy(res, (Map row) => row['date']);
    List<Map> data = [];
    aux.keys.forEach((String date) {
      List bux = aux[date];
      var hB = [];
      var load = [];
      for (Map row in bux) {
        hB.add(row['hourBeginning']);
        load.add(
            new Map.fromIterables(loadKeys, loadKeys.map((key) => row[key])));
      }
      data.add({
        'date': date,
        'version': bux.first['version'],
        'hourBeginning': hB,
        'load': load,
      });
    });

    return data;
  }

  /// Get the file for this month
  File getFile(int year) {
    return new File(dir + 'actual_load_${year.toString()}.xlsx');
  }

  /// Download a file.
  /// https://www.eversource.com/content/ct-c/about/about-us/doing-business-with-us/energy-supplier-information/wholesale-supply-(connecticut)
  Future downloadFile(int year) async {
    File fileout = getFile(year);
    String url =
        'https://www.eversource.com/content/docs/default-source/doing-business/' +
            loadUrls[year];
    if (url == null)
      throw new ArgumentError('Year $year is not in the url Map');

    return new HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));
  }

  Future<Null> setup() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1, 'version': 1}, unique: true);

    await dbConfig.db.close();
  }
}

Map _groupBy(Iterable x, Function f) {
  Map result = new Map();
  x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
  return result;
}
