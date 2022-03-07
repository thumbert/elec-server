library db.isoexpress.da_congestion_compact;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:more/ordering.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
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

  /// Return one document for one day for all ptids in the pool.
  /// Use rle to encode most common values.
  ///
  /// Return a list with each element ready for insertion
  /// into the Db.  In general, the congestion list has 24 elements, one for
  /// each hour of the day.  Each element of the list contains the congestion
  /// values for all the ptids in rle format.  The list of ptids is sorted such
  /// that it encourages significant value compression.
  /// ```
  /// {
  ///   'date': '2020-01-01',
  ///   'ptids': <int>[...],   // 1084 elements or so,
  ///   'congestion': <num>[...],  // 24 elements for most days
  /// }
  /// ```
  @override
  List<Map<String, dynamic>> processFile(File file) {
    var _data = mis.readReportTabAsMap(file, tab: 0);
    if (_data.isEmpty) return <Map<String, dynamic>>[];
    var date = parseMmddyyy(_data.first['Date']);

    // On some days, ISO duplicates the data for one (ptid, HE).  Make sure
    // you only keep one!  See 2019-01-02 for example.
    var aux = groupBy(
            _data,
            (Map row) =>
                Tuple2(int.parse(row['Location ID']), row['Hour Ending']))
        .map((key, value) => MapEntry(key, value.first));
    var dataByPtids =
        groupBy(aux.values, (Map row) => int.parse(row['Location ID']));
    var _ptids = dataByPtids.keys.toList();

    // Initially, store the congestion in a List<List<num>> [ptid][hour].
    // It gets transposed after the sorting.
    var _congestion = <List<num>>[];
    for (var ptid in dataByPtids.keys) {
      _congestion.add(dataByPtids[ptid]!
          .map((e) => e['Congestion Component'] as num)
          .toList());
    }

    /// insert the ptid index at position 0, so you can keep track of the
    /// ptid after you do the sorting.
    for (var i = 0; i < _ptids.length; i++) {
      _congestion[i].insert(0, i);
    }

    /// order the congestion data
    var ordering = Ordering.natural<num>()
        .onResultOf((List xs) => xs[1]) // sort by hour beginning 0
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[2]))
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[3]))
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[4]))
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[6]))
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[9]))
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[12]))
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[15]))
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[18]))
        .compound(Ordering.natural<num>().onResultOf((List xs) => xs[21]));
    ordering.sort(_congestion);

    /// Transpose the _congestion matrix into a
    /// data matrix with index [hour][ptid]
    var hoursCount = _congestion.first.length - 1;
    var data = List.generate(
        hoursCount, (i) => List<num>.generate(_ptids.length, (i) => 999.9));
    for (var i = 0; i < hoursCount; i++) {
      for (var j = 0; j < _ptids.length; j++) {
        data[i][j] = _congestion[j][i + 1];
      }
    }

    var out = {
      'date': date.toString(),
      'ptids': _congestion.map((e) => _ptids[e[0] as int]).toList(),
      'congestion': data.map((List<num> e) => runLenghtEncode(e)).toList(),
    };

    return [out];
  }

  // List<Map<String, dynamic>> processFile(File file) {
  //   var data = mis.readReportTabAsMap(file, tab: 0);
  //   if (data.isEmpty) return <Map<String, dynamic>>[];
  //   var dataByPtids = groupBy(data, (Map row) => int.parse(row['Location ID']));
  //   var _ptids = dataByPtids.keys.toList();
  //
  //   /// One document for the entire file
  //   var congestion = List.generate(_ptids.length, (index) => <num>[]);
  //   for (var i = 0; i < _ptids.length; i++) {
  //     var ptid = _ptids[i];
  //     var rows = dataByPtids[ptid]!;
  //     var hours = <TZDateTime>{};
  //     var values = <num>[]; // rle of the hourly congestion prices
  //
  //     /// Need to check if there are duplicates.  Sometimes the ISO sends
  //     /// the same data twice see ptid: 38206, date: 2019-05-19.
  //     for (var row in rows) {
  //       var hour = parseHourEndingStamp(row['Date'], row['Hour Ending']);
  //       if (!hours.contains(hour)) {
  //         /// if duplicate, insert only once
  //         hours.add(hour);
  //         values.add(row['Congestion Component']);
  //       }
  //     }
  //
  //     /// do the rle
  //     congestion[i].addAll(runLenghtEncode(values, keys: keys));
  //   }
  //
  //   return [
  //     {
  //       'date': formatDate(data.first['Date']),
  //       'ptids': _ptids,
  //       'congestion': congestion,
  //     }
  //   ];
  // }

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
