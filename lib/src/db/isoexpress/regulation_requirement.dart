library db.isoexpress.regulation_requirement;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';

class RegulationRequirementArchive {
  ComponentConfig dbConfig;
  String dir;
  final reportName = 'Regulation Requirement';

  RegulationRequirementArchive({this.dbConfig, this.dir}) {
    var env = Platform.environment;
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'isoexpress'
      ..collectionName = 'regulation_requirement';
    dir ??= env['HOME'] +
        '/Downloads/Archive/IsoExpress/OperationsReports/DailyRegulationRequirement/Raw/';
  }

  Db get db => dbConfig.db;

  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    try {
      await dbConfig.coll.remove(<String,dynamic>{});
      await dbConfig.coll.insertAll(data);
      print('---> Inserted $reportName successfully');
      return Future.value(0);
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
  }

  /// Read all the files
  List<Map<String, dynamic>> readAllData() {
    var data = <Map<String,dynamic>>[
       {
        'from': '2014-04-01',
        'to': '2016-02-24',
        ..._readXlsx(Date(2014, 4, 1)),
      },
      {
        'from': '2016-02-25',
        'to': '2018-07-15',
        ..._readXlsx(Date(2016, 2, 25)),
      },
      {
        'from': '2018-07-16',
        'to': '2099-12-31',
        ..._readXlsx(Date(2018, 7, 16)),
      },
    ];
    return data;
  }

  /// As the regulation requirements change over time, you need to create a new
  /// file, and a new from/to interval.
  Map<String, dynamic> _readXlsx(Date asOfDate) {
    var file =
        File(dir + '${asOfDate.toString()}_daily_regulation_requirement.xlsx');
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    var res = <String, dynamic>{
      'regulation capacity': [],
      'regulation service': [],
    };
    var sheetNames = decoder.tables.keys.toList();
    // Regulation Capacity
    var table = decoder.tables[sheetNames[0]];
    for (int r = 3; r < table.maxRows; r++) {
      var day;
      var dayType = (table.rows[r][0] as String).trim().toLowerCase();
      if (dayType == 'week') {
        day = [1, 2, 3, 4, 5]; // Mon to Fri
      } else if (dayType == 'sat') {
        day = 6;
      } else if (dayType == 'sun') {
        day = 7;
      } else {
        throw ArgumentError('Unknown day: ${table.rows[r][0]}');
      }
      for (int m = 1; m <= 12; m++) {
        (res['regulation capacity'] as List).add({
          'month': m,
          'weekday': day,
          'hourBeginning': table.rows[r][1] - 1,
          'value': table.rows[r][m + 1],
        });
      }
    }
    // Regulation Service
    table = decoder.tables[sheetNames[1]];
    for (int r = 3; r < table.maxRows; r++) {
      var day;
      var dayType = (table.rows[r][0] as String).trim().toLowerCase();
      if (dayType == 'week') {
        day = [1, 2, 3, 4, 5]; // Mon to Fri
      } else if (dayType == 'sat') {
        day = 6;
      } else if (dayType == 'sun') {
        day = 7;
      } else {
        throw ArgumentError('Unknown day: ${table.rows[r][0]}');
      }
      for (int m = 1; m <= 12; m++) {
        (res['regulation service'] as List).add({
          'month': m,
          'dayOfWeek': day,
          'hourBeginning': table.rows[r][1] - 1,
          'value': table.rows[r][m + 1],
        });
      }
    }

    return res;
  }

  /// Return the asOfDate in the yyyy-mm-dd format from the filename.
  /// Filename is just the basename,
  /// and in the form: '2017-08-03_daily_regulation....xlsx'
//  String _getAsOfDate(String filename) => filename.substring(0,10);

  /// Download the file from the ISO.  Append a date to the name.
  /// If the asOfDate is the same as the 2018-07-16, delete the file as it
  /// is not needed.
  Future<int> downloadFile({String url}) async {
    url ??=
        'https://www.iso-ne.com/static-assets/documents/sys_ops/op_frcstng/dlyreg_req/daily_regulation_requirement.xlsx';
    var filename = path.basename(url);
    var fileout = File(dir + Date.today().toString() + '_' + filename);

    await HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));

    // check that the asOfDate is different from the last one, if not,
    // delete this file ...
    var asOfDate = getAsOfDate(fileout);
    if (asOfDate == Date(2018, 7, 16)) {
      fileout.deleteSync();
    } else {
      throw ArgumentError('New as of date!  Please refactor code.');
    }
    return 0;
  }

  /// Return the asOfDate from the regulation requirements file.
  /// Last one is 2018-07-16.
  Date getAsOfDate(File file) {
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    var sheetNames = decoder.tables.keys.toList();
    var table = decoder.tables[sheetNames.first];
    var asOfDate = table.rows[0][1] as String;
    return Date.parse(asOfDate.substring(0, 10));
  }

  List<File> getAllFiles() {
    return Directory(dir)
        .listSync()
        .where((f) => path.extension(f.path).toLowerCase() == '.xlsx')
        .toList()
        .cast<File>();
  }

  /// Recreate the collection from scratch.
  /// Insert all the files in the archive directory.
  setupDb() async {
    if (!Directory(dir).existsSync())
      Directory(dir).createSync(recursive: true);

    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'to': 1, 'from': 1}, unique: true);
    await dbConfig.db.close();
  }
}
