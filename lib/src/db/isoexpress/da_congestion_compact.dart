library db.isoexpress.da_congestion_compact;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/webservices/da_lmp_hourly.dart';
import 'package:more/comparator.dart';
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
    dir ??= '${baseDir}PricingReports/DaLmpHourly/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Congestion Compact Archive';
  }
  final keys = {0, 0.01, 0.02};

  // @override
  // String getUrl(Date? asOfDate) =>
  //     'https://www.iso-ne.com/static-transform/csv/histRpts/da-lmp/WW_DALMP_ISO_${yyyymmdd(asOfDate)}.csv';

  @override
  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/hourlylmp/da/final/day/${yyyymmdd(asOfDate)}';

  @override
  File getFilename(Date asOfDate) {
    if (asOfDate.isBefore(Date.utc(2022, 12, 22))) {
      return File('${dir}WW_DALMP_ISO_${yyyymmdd(asOfDate)}.csv');
    } else {
      return File('${dir}WW_DALMP_ISO_${yyyymmdd(asOfDate)}.json');
    }
  }

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

    /// use the file processor from the DaLmpHourlyArchive
    var damArchive = DaLmpHourlyArchive(dbConfig: dbConfig, dir: dir);
    var docs = damArchive.processFile(file);
    if (docs.isEmpty) return <Map<String, dynamic>>[];

    var ptids = docs.map((e) => e['ptid'] as int).toList();

    /// Initially, store the congestion in a List<List<num>> [ptid][hour].
    /// It gets transposed after the sorting.
    /// Insert the ptid index at position 0, so you can keep track of the
    /// ptid after you do the sorting.
    var congestion = <List<num>>[];
    var i = 0;
    for (var e in docs) {
      congestion.add([i, ...e['congestion']]);
      i++;
    }


    // var _data = mis.readReportTabAsMap(file, tab: 0);
    // if (_data.isEmpty) return <Map<String, dynamic>>[];
    // var date = parseMmddyyy(_data.first['Date']);
    //
    // // On some days, ISO duplicates the data for one (ptid, HE).  Make sure
    // // you only keep one!  See 2019-01-02 for example.
    // var aux = groupBy(
    //         _data,
    //         (Map row) =>
    //             Tuple2(int.parse(row['Location ID']), row['Hour Ending']))
    //     .map((key, value) => MapEntry(key, value.first));
    // var dataByPtids =
    //     groupBy(aux.values, (Map row) => int.parse(row['Location ID']));
    // var _ptids = dataByPtids.keys.toList();
    //
    // // Initially, store the congestion in a List<List<num>> [ptid][hour].
    // // It gets transposed after the sorting.
    // var _congestion = <List<num>>[];
    // for (var ptid in dataByPtids.keys) {
    //   _congestion.add(dataByPtids[ptid]!
    //       .map((e) => e['Congestion Component'] as num)
    //       .toList());
    // }

    // /// insert the ptid index at position 0, so you can keep track of the
    // /// ptid after you do the sorting.
    // for (var i = 0; i < _ptids.length; i++) {
    //   _congestion[i].insert(0, i);
    // }

    /// order the congestion data
    var ordering = naturalComparator<num>()
        .onResultOf((List xs) => xs[1])
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[2]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[3]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[4]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[6]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[9]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[12]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[12]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[15]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[18]))
      .thenCompare(naturalComparator<num>().onResultOf((List xs) => xs[21]));
    ordering.sort(congestion);

    /// Transpose the _congestion matrix into a
    /// data matrix with index [hour][ptid]
    var hoursCount = congestion.first.length - 1;
    var data = List.generate(
        hoursCount, (i) => List<num>.generate(ptids.length, (i) => 999.9));
    for (var i = 0; i < hoursCount; i++) {
      for (var j = 0; j < ptids.length; j++) {
        data[i][j] = congestion[j][i + 1];
      }
    }

    var out = {
      'date': docs.first['date'],
      'ptids': congestion.map((e) => ptids[e[0] as int]).toList(),
      'congestion': data.map((List<num> e) => runLenghtEncode(e)).toList(),
    };

    return [out];
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
