import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/lib_pjm_reports.dart';
import 'package:more/comparator.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:dama/basic/rle.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:elec_server/src/db/config.dart';

class PjmDaCongestionCompactArchive extends DailyPjmCsvReport {
  /// A collection for storing congestion only prices to get fast access to
  /// all hourly prices for all locations in PJM.
  ///
  ///
  PjmDaCongestionCompactArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'pjm',
        collectionName: 'da_congestion_compact');
    this.dbConfig = dbConfig;
    dir ??= '${super.dir}Lmp/Dam/Raw/';
    this.dir = dir;
    reportName = 'Hourly DA Congestion Compact';
  }

  Db get db => dbConfig.db;

  @override
  String getUrl(Date asOfDate) => throw UnimplementedError(
      'File download should be done in a different process.');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    return <String, dynamic>{};
  }

  /// Insert data into db.  You can pass in several days at once.
  /// Note: Input [data] needs to contain both the zone and the gen data
  /// because data is inserted by date.
  @override
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
        print('--->  Inserted NYISO DAM congestion compact for day $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.close();
  }

  @override
  Date getReportDate(File file) {
    var yyyymmdd = basename(file.path).substring(0, 8);
    return Date.utc(
        int.parse(yyyymmdd.substring(0, 4)),
        int.parse(yyyymmdd.substring(4, 6)),
        int.parse(yyyymmdd.substring(6, 8)));
  }

  /// Make a document from all nodes in the pool.
  ///
  /// Return a one element list ready for insertion into the Db.  In general,
  /// the congestion list has 24 elements, one for each hour of the day.
  /// Each element of the list contains the congestion
  /// values for the ptids in rle format.  The list of ptids is sorted such
  /// that it encourages significant value compression.
  /// ```
  /// {
  ///   'date': '2020-01-01',
  ///   'ptids': <int>[...],
  ///   'congestion': <num>[...],
  /// }
  /// ```
  @override
  List<Map<String, dynamic>> processDate(Date date) {
    var out = <String, dynamic>{};

    var _ptids = <int>[];
    // Initially, store the congestion in a List<List<num>> [ptid][hour].
    // It gets transposed after the sorting.
    var _congestion = <List<num>>[];

    /// Get the congestion for all the nodes and construct the _congestion
    /// matrix.
    var xs = readZipReport(date);
    if (xs.isEmpty) return [out];
    var groups = groupBy(xs, (Map e) => e['pnode_id'] as int);
    for (var group in groups.entries) {
      _ptids.add(group.key);
      _congestion.add(
          group.value.map((e) => e['congestion_price_da'] as num).toList());
    }

    /// insert the ptid index at position 0, so you can keep track of the
    /// ptid after you do the sorting.
    for (var i = 0; i < _ptids.length; i++) {
      _congestion[i].insert(0, i);
    }

    /// order the congestion data
    var ordering = naturalComparable<num>.onResultOf(
            (List xs) => xs[1]) // sort by hour beginning 0
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[2]))
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[3]))
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[4]))
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[6]))
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[9]))
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[12]))
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[15]))
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[18]))
        .thenCompare(naturalComparable<num>.onResultOf((List xs) => xs[21]));
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

    out = {
      'date': date.toString(),
      'ptids': _congestion.map((e) => _ptids[e[0] as int]).toList(),
      'congestion': data.map((List<num> e) => runLenghtEncode(e)).toList(),
    };

    return [out];
  }

  @override
  File getCsvFile(Date asOfDate) {
    return File('${dir}da_hrl_lmps_$asOfDate.csv');
  }
}
