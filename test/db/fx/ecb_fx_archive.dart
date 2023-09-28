library db.isoexpress.da_lmp_hourly;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:path/path.dart';

/// TODO: continue
class EcbFxArchive {
  EcbFxArchive({ComponentConfig? dbConfig, String? dir}) {
    this.dbConfig = dbConfig ?? ComponentConfig(
        host: '127.0.0.1',
        dbName: 'fx',
        collectionName: 'ecb');
    this.dir = dir ?? '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Fx/Ecb/Raw/';
  }

  late final ComponentConfig dbConfig;
  late final String dir;

  String getUrl() =>
    'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.zip';

  /// Keep one file for the entire year.
  File getFilename(Date asOfDate, {String extension = 'csv'}) {
    if (extension == 'csv') {
      return File('${dir}eurofxref-hist_${asOfDate.year}.csv');
    } else {
      throw StateError('Unsupported extension $extension');
    }
  }

  /// Insert data into db.  You can pass in several years at once.
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data');
      return Future.value(-1);
    }
    var groups = groupBy(data, (Map e) => e['date']);
    try {
      for (var date in groups.keys) {
        await dbConfig.coll.remove({'date': date});
        await dbConfig.coll.insertAll(groups[date]!);
        print('--->  Inserted FX history as of $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  /// Input [file] is always ending in json.  You can use older csv files for
  /// compatibility but if a new download is initiated (after 2022-12-21),
  /// the file will be json.
  ///
  /// Return a Map with elements like this
  /// ```dart
  /// {
  ///   'date': '2022-12-22',
  ///   'ptid': 321,
  ///   'congestion': <num>[...],
  ///   'lmp': <num>[...],
  ///   'marginal_loss: <num>[...],
  /// }
  /// ```
  List<Map<String, dynamic>> processFile(File file) {
    if (file.existsSync()) {
      if (file.path.endsWith('.csv')) {
        return _processFileCsv(file);
      } else {
        throw ArgumentError('No csv ${basename(file.path)} file exists!');
      }
    } else {
      throw ArgumentError('File $file does not exist!');
    }
  }


  List<Map<String, dynamic>> _processFileCsv(File file) {
    // var data = mis.readReportTabAsMap(file, tab: 0);
    // if (data.isEmpty) return <Map<String, dynamic>>[];
    // var dataByPtids = groupBy(data, (dynamic row) => row['Location ID']);
    // return dataByPtids.keys
    //     .map((ptid) => _converterCsv(dataByPtids[ptid]!))
    //     .toList();
    return [];
  }


  /// need to split the file into years
  Future downloadFile() async {
    var client = HttpClient()
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var request = await client.getUrl(Uri.parse(getUrl()));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    var file = File('${dir}eurofxref-hist.zip');
    await response.pipe(file.openWrite());
  }

  /// Recreate the collection from scratch.
  Future<void> setupDb() async {
    await dbConfig.db.open();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'date': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.close();
  }

}
