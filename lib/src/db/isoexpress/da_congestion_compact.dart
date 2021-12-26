library db.isoexpress.da_congestion_compact;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:dama/basic/rle.dart';

class DaCongestionCompactArchive extends DailyIsoExpressReport {
  DaCongestionCompactArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'isoexpress',
        collectionName: 'da_congestion_compact');
    this.dbConfig = dbConfig;
    dir ??= baseDir + 'PricingReports/DaLmpHourly/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Congestion Compact Archive';
  }
  final keys = {0, 0.01, 0.02};

  @override
  String getUrl(Date? asOfDate) =>
      'https://www.iso-ne.com/static-transform/csv/histRpts/da-lmp/'
          'WW_DALMP_ISO_' +
      yyyymmdd(asOfDate) +
      '.csv';
  @override
  File getFilename(Date? asOfDate) =>
      File(dir + 'WW_DALMP_ISO_' + yyyymmdd(asOfDate) + '.csv');

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    var dataByPtids =
        groupBy(data, (dynamic row) => int.parse(row['Location ID']));
    var _ptids = dataByPtids.keys.toList();

    /// One document for the entire file
    var congestion = List.generate(_ptids.length, (index) => <num>[]);
    for (var i = 0; i < _ptids.length; i++) {
      var ptid = _ptids[i];
      var rows = dataByPtids[ptid]!;
      var hours = <TZDateTime>{};
      var values = <num>[]; // rle of the hourly congestion prices

      /// Need to check if there are duplicates.  Sometimes the ISO sends
      /// the same data twice see ptid: 38206, date: 2019-05-19.
      for (var row in rows) {
        var hour = parseHourEndingStamp(row['Date'], row['Hour Ending']);
        if (!hours.contains(hour)) {
          /// if duplicate, insert only once
          hours.add(hour);
          values.add(row['Congestion Component']);
        }
      }

      /// do the rle
      congestion[i].addAll(runLenghtEncode(values, keys: keys));
    }

    return [
      {
        'date': formatDate(data.first['Date']),
        'ptids': _ptids,
        'congestion': congestion,
      }
    ];
  }

  /// Recreate the collection from scratch.
  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.close();
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    // TODO: implement converter
    throw UnimplementedError();
  }
}
