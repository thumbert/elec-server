library db.nyiso.da_congestion_compact;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:dama/basic/rle.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/src/db/lib_nyiso_report.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:elec_server/src/db/config.dart';
import 'package:more/ordering.dart';

class NyisoDaCongestionCompactArchive extends DailyNysioCsvReport {
  /// A collection for storing congestion only prices to get fast access to
  /// all hourly prices for all locations available for TCCs.
  ///
  /// With rle, storing Jan19 data (31 documents) takes 16 kB of storage.
  ///
  NyisoDaCongestionCompactArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'nyiso',
        collectionName: 'da_congestion_compact');
    this.dbConfig = dbConfig;
    dir ??= super.dir + 'DaLmpHourly/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Hourly LMP';
  }

  Db get db => dbConfig.db;
  late NodeType nodeType;

  /// A set of ptids to store in the db.  Not all locations are available for
  /// TCCs.
  Set<int>? ptids;

  /// Data available for the most 10 recent days only at this url.
  /// http://mis.nyiso.com/public/csv/damlbmp/20220113damlbmp_zone.csv
  /// Entire month is at
  /// http://mis.nyiso.com/public/csv/damlbmp/20211201damlbmp_zone_csv.zip
  /// http://mis.nyiso.com/public/csv/damlbmp/20211201damlbmp_gen_csv.zip
  @override
  String getUrl(Date asOfDate) =>
      'http://mis.nyiso.com/public/csv/damlbmp/' +
      yyyymmdd(asOfDate) +
      'damlbmp_${nodeType.toString()}.csv';

  @override
  File getCsvFile(Date asOfDate) =>
      File(dir + yyyymmdd(asOfDate) + 'damlbmp_${nodeType.toString()}.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    return <String, dynamic>{};
  }

  /// Make a document from all nodes in the pool.
  ///
  /// Return a list with each element ready for insertion
  /// into the Db.  In general, the congestion list has 24 elements, one for
  /// each hour of the day.  Each element of the list contains the congestion
  /// values for the ptids in rle format.  The list of ptids is sorted such
  /// that it encourages significant value compression.
  /// ```
  /// {
  ///   'date': '2020-01-01',
  ///   'ptids': <int>[...],
  ///   'congestion': <num>[...],
  /// }
  /// ```
  Map<String, dynamic> processDay(Date date) {
    var out = <String, dynamic>{};

    var _ptids = <int>[];
    // Initially, store the congestion in a List<List<num>> [ptid][hour].
    // It gets transposed after the sorting.
    var _congestion = <List<num>>[];

    /// Get the congestion from both the zones and the gen nodes and construct
    /// the _congestion matrix.
    var nodeTypes = [NodeType.zone, NodeType.gen];
    for (var _nodeType in nodeTypes) {
      nodeType = _nodeType;
      var xs = readReport(date);
      if (xs.isEmpty) return out;
      var groups = groupBy(xs, (Map e) => e['PTID'] as int);
      for (var group in groups.entries) {
        if (ptids == null || ptids!.contains(group.key)) {
          // only when the ptid is in the set of ptids that are needed
          _ptids.add(group.key);
          _congestion.add(group.value
              .map((e) => e['Marginal Cost Congestion (\$/MWHr)'] as num)
              .toList());
        }
      }
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

    out = {
      'date': date.toString(),
      'ptids': _congestion.map((e) => _ptids[e[0] as int]).toList(),
      'congestion': data.map((List<num> e) => runLenghtEncode(e)).toList(),
    };

    return out;
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
        print('--->  Inserted NYISO DAM LMPs for day $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx ' + e.toString());
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

  @override
  List<Map<String, dynamic>> processFile(File file) {
    /// use processDay()
    throw UnimplementedError();
  }

  @override
  String getUrlForMonth(Month month) =>
      'http://mis.nyiso.com/public/csv/damlbmp/' +
      month.startDate.toString().replaceAll('-', '') +
      'damlbmp_${nodeType.toString()}_csv.zip';

  @override
  File getZipFileForMonth(Month month) {
    return File(dir +
        month.startDate.toString().replaceAll('-', '') +
        'damlbmp_${nodeType.toString()}.csv.zip');
  }
}
