library db.nyiso.da_congestion_compact;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/src/db/lib_nyiso_report.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:more/ordering.dart';

class NyisoDaCongestionCompactArchive extends DailyNysioCsvReport {
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
  File getFile(Date asOfDate) =>
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

    var ptids = <int>[];
    var _congestion = <List<num>>[]; // Matrix with indices [ptid,hour]

    /// Get the congestion from both the zones and the gen nodes and construct
    /// the _congestion matrix.
    var nodeTypes = [NodeType.zone, NodeType.gen];
    for (var _nodeType in nodeTypes) {
      nodeType = _nodeType;
      var xs = readReport(date);
      if (xs.isEmpty) return out;
      var groups = groupBy(xs, (Map e) => e['PTID'] as int);
      for (var group in groups.entries) {
        ptids.add(group.key);
        _congestion.add(group.value
            .map((e) => e['Marginal Cost Congestion (\$/MWHr)'] as num)
            .toList());
      }
    }
    /// insert the ptid index at position 0
    for (var i=0; i<ptids.length; i++) {
      _congestion[i].insert(0, i);
    }

    /// order the congestion data
    var ordering = Ordering.natural<num>()
        .onResultOf((List xs) => xs[1]) // by hour beginning 0
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
    /// data matrix with index [hour, ptid]
    var hoursCount = _congestion.first.length - 1;
    var data = List.generate(
        hoursCount, (i) => List<num>.generate(ptids.length, (i) => 999.9));
    for (var i = 0; i < hoursCount; i++) {
      for (var j = 0; j < ptids.length; j++) {
        data[i][j] = _congestion[j][i+1];
      }
    }

    out = {
      'date': date.toString(),
      'ptids': _congestion.map((e) => ptids[e[0] as int]).toList(),
      'congestion': data.map((List<num> e) => rle(e)).toList(),
    };

    return out;
  }

  List<num> rle(List<num> xs) {

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
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'date': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'ptid': 1});
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
}
