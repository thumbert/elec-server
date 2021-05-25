library db.isoexpress.regulation_requirement;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';

class RegulationRequirementArchive {
  late ComponentConfig dbConfig;
  String? dir;
  final reportName = 'Regulation Requirement';

  RegulationRequirementArchive({ComponentConfig? dbConfig, this.dir}) {
    var env = Platform.environment;
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'regulation_requirement');
    }
    dir ??= env['HOME']! +
        '/Downloads/Archive/IsoExpress/OperationsReports/DailyRegulationRequirement/Raw/';
  }

  Db? get db => dbConfig.db;

  /// Always insert ALL available historical data
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    try {
      await dbConfig.coll.remove(<String, dynamic>{}); // empty the collection
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
    var data = <Map<String, dynamic>>[];

    if (readXlsx(Date.utc(2014, 4, 1)).isNotEmpty) {
      data.add({
        'from': '2014-04-01',
        'to': '2016-02-24',
        ...readXlsx(Date.utc(2014, 4, 1)),
      });
    }

    if (readXlsx(Date.utc(2016, 2, 25)).isNotEmpty) {
      data.add({
        'from': '2016-02-25',
        'to': '2018-07-15',
        ...readXlsx(Date.utc(2016, 2, 25)),
      });
    }

    if (readXlsx(Date.utc(2018, 7, 16)).isNotEmpty) {
      data.add({
        'from': '2018-07-16',
        'to': '2021-02-09',
        ...readXlsx(Date.utc(2018, 7, 16)),
      });
    }

    if (readXlsx(Date.utc(2021, 2, 10)).isNotEmpty) {
      data.add({
        'from': '2021-02-10',
        'to': '2099-12-31',
        ...readXlsx(Date.utc(2021, 2, 10)),
      });
    }

    return data;
  }

  Map<String, dynamic> readFile(File file) {
    if (!file.existsSync()) {
      return <String, dynamic>{};
    }
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    var res = <String, dynamic>{
      'regulation capacity': [],
      'regulation service': [],
    };
    var sheetNames = decoder.tables.keys.toList();
    // Regulation Capacity
    var ind = sheetNames.where((e) => e.contains('Reg Cap Reqmnt')).first;
    var table = decoder.tables[ind]!;
    for (var r = 3; r < table.maxRows; r++) {
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
      for (var m = 1; m <= 12; m++) {
        (res['regulation capacity'] as List).add({
          'month': m,
          'weekday': day,
          'hourBeginning': table.rows[r][1] - 1,
          'value': table.rows[r][m + 1],
        });
      }
    }
    // Regulation Service
    ind = sheetNames.where((e) => e.contains('Reg Service Reqmnt')).first;
    table = decoder.tables[ind]!;
    for (var r = 3; r < table.maxRows; r++) {
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
      for (var m = 1; m <= 12; m++) {
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

  /// As the regulation requirements change over time, you need to create a new
  /// file, and a new from/to interval.
  Map<String, dynamic> readXlsx(Date asOfDate) {
    var file =
        File(dir! + '${asOfDate.toString()}_daily_regulation_requirement.xlsx');
    return readFile(file);
  }

  /// Return the asOfDate in the yyyy-mm-dd format from the filename.
  /// Filename is just the basename,
  /// and in the form: '2017-08-03_daily_regulation....xlsx'
//  String _getAsOfDate(String filename) => filename.substring(0,10);

  /// Download the file from the ISO.  Append a date to the name.
  /// If the asOfDate is the same as the 2018-07-16, delete the file as it
  /// is not needed.
  Future<int> downloadFile({String? url}) async {
    url ??=
        'https://www.iso-ne.com/static-assets/documents/sys_ops/op_frcstng/dlyreg_req/daily_regulation_requirement.xlsx';
    var filename = path.basename(url);
    var fileout = File(dir! + Date.today(location: UTC).toString() + '_' + filename);

    await HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));

    var asOfDate = getAsOfDate(fileout);
    // Check that this file is in the archive.  If not, save it.
    var lastFile = File(dir! + asOfDate.toString() + '_' + filename);
    if (!lastFile.existsSync()) {
      fileout.copySync(lastFile.path.toString());
    }
    // check that the asOfDate is different from the last one, if not,
    // delete this file ...
    if (asOfDate == Date.utc(2021, 2, 10)) {
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
    var table = decoder.tables[sheetNames.first]!;
    var asOfDate = table.rows[0][1] as String;
    return Date.parse(asOfDate.substring(0, 10));
  }

  List<File> getAllFiles() {
    return Directory(dir!)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('_daily_regulation_requirement.xlsx'))
        .toList();
  }

  /// Recreate the collection from scratch.
  /// Insert all the files in the archive directory.
  Future<void> setupDb() async {
    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }

    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'to': 1, 'from': 1}, unique: true);
    await dbConfig.db.close();
  }
}
