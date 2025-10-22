import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:archive/archive.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart';
import '../lib_iso_express.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class RtSystemLoad5minArchive extends DailyIsoExpressReport {
  /// Data available from 2021-08-01 forward
  RtSystemLoad5minArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'isoexpress',
        collectionName: 'rt_systemload_5min');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}Demand/SystemDemand5min/Raw';
    this.dir = dir;
    reportName = 'Five-Minute System Demand';
  }

  @override
  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/fiveminutesystemload/day/${yyyymmdd(asOfDate)}';

  /// I encoded the json file using msgpack and got only a marginal improvement
  /// to file size.  File size went down from 6.2 MB to 5.6 MB.  GZipping the
  /// file reduces it to 0.5 MB.
  ///
  @override
  File getFilename(Date asOfDate) {
    final year = asOfDate.year;
    return File('$dir/$year/isone_systemload_5min_$asOfDate.json.gz');
  }

  /// Insert data into db.  You can pass in several days at once.
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data to insert');
      return Future.value(-1);
    }
    try {
      for (var e in data) {
        await dbConfig.coll.remove({'date': e['date']});
        await dbConfig.coll.insertOne(e);
        print('--->  Inserted ISONE 5min system load for day ${e['date']}');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  /// Input [file] is a gziped json file.
  ///
  /// Return a one element List like this
  /// ```dart
  /// {
  ///   'date': '2023-12-01',
  ///   'minuteStart': <int>[...],
  ///   'load': <num>[...],
  ///   'nativeLoad': <num>[...],
  ///   'ardDemand': <num>[...],
  ///   'systemLoadBtmPv': <num>[...],
  ///   'nativeLoadBtmPv': <num>[...],
  /// }
  /// ```
  @override
  List<Map<String, dynamic>> processFile(File file) {
    if (!file.existsSync()) {
      throw ArgumentError('File $file does not exist!');
    }
    if (extension(file.path) != '.gz') {
      throw ArgumentError('File $file needs to be a gzip archive!');
    }
    final bytes = file.readAsBytesSync();
    var content = GZipDecoder().decodeBytes(bytes);
    var json = utf8.decoder.convert(content);
    return [_processJson(json)];
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    return <String, dynamic>{};
  }

  Map<String, dynamic> _processJson(String input) {
    var x = json.decode(input) as Map<String, dynamic>;
    if (x
        case {
          'FiveMinSystemLoads': {
            'FiveMinSystemLoad': List entries,
          }
        }) {
      var date = Date.fromIsoString(
          (entries.first['BeginDate'] as String).substring(0, 10),
          location: IsoNewEngland.location);

      // check that you have all the 5 min intervals
      final count = date.hours().length;
      if (entries.length != count * 12) {
        print(
            'NOTE: Missing ${count * 12 - entries.length} 5min intervals for $date');
      }

      // assume that the intervals are correctly ordered
      var out = <String, dynamic>{
        'date': date.toString(),
        'minuteOffset': <int>[],
        'load': <num>[],
        'nativeLoad': <num>[],
        'ardDemand': <num>[],
        'systemLoadBtmPv': <num>[],
        'nativeLoadBtmPv': <num>[],
      };
      for (var e in entries) {
        if (e
            case {
              'BeginDate': String dt,
              'LoadMw': num load,
              'NativeLoad': num nativeLoad,
              'ArdDemand': num ardDemand,
              'SystemLoadBtmPv': num systemLoadBtmPv,
              'NativeLoadBtmPv': num nativeLoadBtmPv,
            }) {
          var midnight = date.start;
          var offset = TZDateTime.parse(IsoNewEngland.location, dt)
              .difference(midnight)
              .inMinutes;
          out['load'].add(load);
          out['minuteOffset'].add(offset);
          out['nativeLoad'].add(nativeLoad);
          out['ardDemand'].add(ardDemand);
          out['systemLoadBtmPv'].add(systemLoadBtmPv);
          out['nativeLoadBtmPv'].add(nativeLoadBtmPv);
        } else {
          throw ArgumentError('Entry $e is not in the correct format!');
        }
      }
      return out;
    } else {
      throw ArgumentError('Input is not in the correct format!');
    }
  }

  @override
  Future downloadDay(Date day) async {
    var user = dotenv.env['ISONE_WS_USER']!;
    var pwd = dotenv.env['ISONE_WS_PASSWORD']!;

    var client = HttpClient()
      ..addCredentials(
          Uri.parse(getUrl(day)), '', HttpClientBasicCredentials(user, pwd))
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var request = await client.getUrl(Uri.parse(getUrl(day)));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    var file = File('$dir/${day.year}/isone_systemload_5min_$day.json');
    if (!Directory(dirname(file.path)).existsSync()) {
      Directory(dirname(file.path)).createSync(recursive: true);
    }
    await response.pipe(file.openWrite());
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'date': 1,
    });
    await dbConfig.db.close();
  }
}
