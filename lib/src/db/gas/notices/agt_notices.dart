library db.gas.notices.agt_notices;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';

class AgtNoticesArchive {
  AgtNoticesArchive() {
    dbConfig = ComponentConfig(
        host: '127.0.0.1', dbName: 'gas', collectionName: 'critical_notices');
    dir =
        '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Gas/CriticalNotices/Agt/Raw/';
  }

  late ComponentConfig dbConfig;
  late String dir;
  final String reportName = 'Critical Notices';
  Db get db => dbConfig.db;

  /// Get all the relative urls from a pipe, AG = Algonquin and a type,
  /// 'CRI' = Critical.
  ///
  /// Return a list with relative URLs like this
  /// ```
  /// [
  ///    'NoticeListDetail.asp?strKey1=123351&type=CRI&Embed=2&pipe=AG',
  ///    ...
  /// ]
  /// ```
  Future<List<Uri>> getUris({String pipeline = 'AG', String type = 'CRI'}) async {
    var url = 'https://infopost.enbridge.com/InfoPost/NoticesList.asp?pipe=$pipeline&type=$type';
    var res = await get(Uri.parse(url));

    var document = parse(res.body);
    var body = document.body!;
    var main = body.children.first;
    var tbody = main.querySelector('tbody')!;
    var colnames = tbody.children.first.nodes.map((e) => e.text).toList();
    if (!ListEquality().equals(colnames,['Notice Type', 'Posted Date/Time', 'Notice Effective Date/Time',
      'Notice End Date/Time', 'Notice Identifier', 'Subject', 'Response Date/Time'])) {
      throw StateError('Table format has changed!  Aborting.');
    }

    /// the link to the actual post is the 5th child
    var uris = tbody.children.skip(1).map((e) {
      var a = e.children[5].querySelector('a')?.attributes;
      return a!['href']!;
    }).toList();

    return uris.map((e) => Uri.parse('https://infopost.enbridge.com/InfoPost/$e')).toList();
  }

  Future<void> saveUrisToDisk(List<Uri> uris) async {
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    for (var uri in uris) {
      var params = uri.queryParameters;
      var file = File(join(dir,
          '${params['strKey1']}_${params['pipe']}_${params['type']}.txt'));
      if (!file.existsSync()) {
        var res = await get(uri);
        file.writeAsStringSync(res.body);
      }
    }
  }

  /// Historical notices for the past 3 years are in Pdf format only
  /// https://linkwc.enbridge.com/HistoricalNotices/AGT/CRI/2019/January%202019.pdf
  Future<void> savePdfToDisk(List<Month> months, {String pipeline = 'AGT', String type = 'CRI'}) async {
    var dir1 = join(dir, 'Pdf');
    if (!Directory(dir1).existsSync()) {
      Directory(dir1).createSync(recursive: true);
    }
    for (var month in months) {
      var aux = '${monthMap[month.month]} ${month.year}.pdf';
      var uri = Uri.parse('https://linkwc.enbridge.com/HistoricalNotices/$pipeline/$type/${month.year}/$aux');
      var file = File(join(dir1,
          '${pipeline}_${month.toIso8601String()}.pdf'));
      if (!file.existsSync()) {
        var res = await get(uri);
        file.writeAsBytesSync(res.bodyBytes);
      }
    }
  }

  static const monthMap = <int,String>{
    1: 'January',
    2: 'February',
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December',
  };


  ///
  // String getFilename(int id, String pipeline, String type) {
  //
  // }


  /// Input [file] is the daily CSV file,
  /// Encode the system value with ptid = -1.
  /// Return a list with each element of this form, ready for insertion.
  /// ```
  /// {
  ///   'type': 'forecast',
  ///   'date': '2020-11-17'
  ///   'ptid': 61757,
  ///   'mw': [0, 0, ...],  // 24 hourly values
  /// }
  /// ```
  // @override
  // List<Map<String, dynamic>> processFile(File file) {
  //   var out = <Map<String, dynamic>>[];
  //
  //   var nameToPtid = NewYorkIso().loadZoneNameToPtid;
  //   var date = getReportDate(file);
  //   var xs = readReport(date);
  //   if (xs.isEmpty) return out;
  //
  //   var grp = groupBy(xs, (Map e) => e['Zone Name'] as String);
  //
  //   for (var zoneName in grp.keys) {
  //     int ptid;
  //     if (nameToPtid.containsKey(zoneName)) {
  //       ptid = nameToPtid[zoneName]!;
  //     } else if (zoneName == 'SYSTEM') {
  //       ptid = -1;
  //     } else {
  //       throw StateError('Unknown NYISO zone name $zoneName');
  //     }
  //     out.add({
  //       'type': 'forecast',
  //       'date': date.toString(),
  //       'ptid': ptid,
  //       'mw': grp[zoneName]!.map((e) => e['MW Value']).toList(),
  //     });
  //   }
  //
  //   return out;
  // }

  /// Insert data into db.  You can pass in several days at once.
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data');
      return Future.value(-1);
    }

    var groups = groupBy(data, (Map e) => Tuple2(e['type'], e['date']));
    try {
      for (var t2 in groups.keys) {
        await dbConfig.coll.remove({'type': t2.item1, 'date': t2.item2});
        await dbConfig.coll.insertAll(groups[t2]!);
        print(
            '--->  Inserted ${t2.item1} NYISO BTM solar forecasted MW for day ${t2.item2}');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'type': 1, 'date': 1, 'ptid': 1});
    await dbConfig.db.close();
  }

}

class Notice {
  Notice(
      {required this.id,
      required this.type,
      required this.postedDateTime,
      required this.effectiveDateTime,
      required this.endDateTime,
      required this.transmissionServiceProvider,
      required this.subject,
      required this.body});

  final int id;
  final String type;
  final TZDateTime postedDateTime;
  final TZDateTime effectiveDateTime;
  final TZDateTime endDateTime;
  final String transmissionServiceProvider; // Algonquin Gas Transmission, LLC
  final String subject;
  final String body;
}
