library db.isoexpress.daily_regulation_requirement;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';

class DailyRegulationRequirementArchive {
  ComponentConfig config;
  String dir;
  final reportName = 'Daily Regulation Requirement';

  DailyRegulationRequirementArchive({this.config, this.dir}) {
    var env = Platform.environment;
    config ??= ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isone'
        ..collectionName = 'daily_regulation_requirement';
    dir ??= env['HOME'] + '/Downloads/Archive/DailyRegulationRequirement/Raw/';
  }

  Db get db => config.db;

  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    try {
      await config.coll.remove({});
      await config.coll.insertAll(data);
      print('---> Inserted $reportName successfully');
      return Future.value(0);
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
  }

  /// Read all the files
  List<Map<String,dynamic>> readAllData() {
    var data = <Map<String,dynamic>>[
      _readXlsx_20180716(),
    ];
    return data;
  }

  Map<String,dynamic> _readXlsx_20180716() {
    var file = File(dir + '2018-07-16_daily_regulation_requirement.xlsx');
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    var res = {
      'from': '2018-07-16',
      'to': '2099-12-31',
      'regulation capacity': [],
      'regulation service': [],
    };
    var table = decoder.tables['Reg Cap Reqmnt a-o 07-16-18'];
    for (int r=3; r<table.maxRows; r++) {
      var day;
      if (table.rows[r][0] == 'week') {
        day = [1, 2, 3, 4, 5];  // Mon to Fri
      } else if (table.rows[r][0] == 'sat') {
        day = 6;
      } else if (table.rows[r][0] == 'sun') {
        day = 7;
      } else {
        throw ArgumentError('Unknown day: ${table.rows[r][0]}');
      }
      for (int m=1; m <= 12; m++) {
        (res['regulation capacity'] as List).add({
          'month': m,
          'dayOfWeek': day,
          'hourBeginning': table.rows[r][1] - 1,
          'value': table.rows[r][m+1],
        });
      }
    }

    table = decoder.tables['Reg Service Reqmnt a-o 07-16-18'];
    for (int r=3; r<table.maxRows; r++) {
      var day;
      if (table.rows[r][0] == 'week') {
        day = [1, 2, 3, 4, 5];  // Mon to Fri
      } else if (table.rows[r][0] == 'sat') {
        day = 6;
      } else if (table.rows[r][0] == 'sun') {
        day = 7;
      } else {
        throw ArgumentError('Unknown day: ${table.rows[r][0]}');
      }
      for (int m=1; m <= 12; m++) {
        (res['regulation service'] as List).add({
          'month': m,
          'dayOfWeek': day,
          'hourBeginning': table.rows[r][1] - 1,
          'value': table.rows[r][m+1],
        });
      }
    }

    return res;
  }


  /// Return the asOfDate in the yyyy-mm-dd format from the filename.
  /// Filename is just the basename,
  /// and in the form: '2017-08-03_daily_regulation....xlsx'
  String _getAsOfDate(String filename) => filename.substring(0,10);

  /// Download the file from the ISO.  Append a date to the name.
  Future downloadFile(String url) async {
    url ??= 'https://www.iso-ne.com/static-assets/documents/sys_ops/op_frcstng/dlyreg_req/daily_regulation_requirement.xlsx';
    var filename = path.basename(url);
    var fileout = File(dir + Date.today().toString() + '_' + filename);

    return HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
        response.pipe(fileout.openWrite()));
  }

  /// Recreate the collection from scratch.
  /// Insert all the files in the archive directory.
  setup() async {
    if (!Directory(dir).existsSync())
      Directory(dir).createSync(recursive: true);

    await config.db.open();
    await config.db.createIndex(config.collectionName,
        keys: {'to': 1, 'from': 1}, unique: true);
    await config.db.close();
  }

}

