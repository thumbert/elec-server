library api.nepool_lmp;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';



/// update it from the package elec.
@ApiClass(name: 'dalmp', version: 'v1')
class DaLmp {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'lmp_hourly';

  DaLmp(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/dalmp/v1/congestion/byrow/ptid/4000
  @ApiMethod(path: 'congestion/byrow/ptid/{ptid}')
  Future<List<Map<String, String>>> apiGetHourlyCongestionData(int ptid) {
    return getHourlyCongestionData(ptid).map((e) => _mccMessage(e)).toList();
  }

  @ApiMethod(path: 'lmp/bycolumn/ptid/{ptid}')
  Future<Map<String,List<String>>> apiGetHourlyLmpDataColumn(int ptid) async {
    var t2 = await getHourlyDataColumn(ptid, 'lmp');
    return {'hourBeginning': t2.item1, 'lmp': t2.item2};
  }


  @ApiMethod(path: 'congestion/bycolumn/ptid/{ptid}')
  Future<Map<String,List<String>>> apiGetHourlyCongestionDataColumn(int ptid) async {
    var t2 = await getHourlyDataColumn(ptid, 'congestion');
    return {'hourBeginning': t2.item1, 'congestion': t2.item2};
  }

  @ApiMethod(path: 'loss/bycolumn/ptid/{ptid}')
  Future<Map<String,List<String>>> apiGetHourlyLossDataColumn(int ptid) async {
    var t2 = await getHourlyDataColumn(ptid, 'loss');
    return {'hourBeginning': t2.item1, 'loss': t2.item2};
  }


  @ApiMethod(path: 'congestion/bycolumn/ptid/{ptid}/start/{start}')
  Future<Map<String, List<String>>> apiGetHourlyCongestionDataStart(
      int ptid, String start) async {
    Date startDate = Date.parse(start);
    var t2 = await getHourlyDataColumn(ptid, 'congestion', startDate: startDate);
    return {'hourBeginning': t2.item1, 'congestion': t2.item2};
  }

  @ApiMethod(path: 'congestion/bycolumn/ptid/{ptid}/end/{end}')
  Future<Map<String, List<String>>> apiGetHourlyCongestionDataEnd(
      int ptid, String end) async {
    Date endDate = Date.parse(end);
    var t2 = await getHourlyDataColumn(ptid, 'congestion', endDate: endDate);
    return {'hourBeginning': t2.item1, 'congestion': t2.item2};
  }

  @ApiMethod(path: 'congestion/bycolumn/ptid/{ptid}/start/{start}/end/{end}')
  Future<Map<String, List<String>>> apiGetHourlyCongestionDataStartEnd(
      int ptid, String start, String end) async {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    var t2 = await getHourlyDataColumn(ptid, 'congestion', startDate: startDate, endDate: endDate);
    return {'hourBeginning': t2.item1, 'congestion': t2.item2};
  }

  @ApiMethod(path: 'ptids')
  Future<List<int>> allPtids() async {
    Map res = await coll.distinct('ptid');
    return res['values'];
  }

  Map _mccMessage(Tuple2<Hour, num> e) =>
      {'HB': e.item1.start.toString(), 'mcc': e.item2};

  /// Get the hourly congestion data between two dates,
  /// from [startDate, endDate] Date.   This includes the hours from
  /// endDate.
  ///
  Stream<Tuple2<Hour, num>> getHourlyCongestionData(int ptid,
      {Date startDate, Date endDate}) {
    List pipeline = [];
    Map match = {
      'ptid': {'\$eq': ptid}
    };
    Map hb = {};
    if (startDate != null) {
      TZDateTime start = new TZDateTime(
          _location, startDate.year, startDate.month, startDate.day);
      hb['\$gte'] = start;
    }
    if (endDate != null) {
      endDate = endDate.add(1);
      TZDateTime end =
          new TZDateTime(_location, endDate.year, endDate.month, endDate.day);
      hb['\$lt'] = end;
    }
    if (hb.isNotEmpty) match['hourBeginning'] = hb;

    Map project = {'_id': 0, 'hourBeginning': 1, 'mcc': '\$congestion'};

    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    return coll.aggregateToStream(pipeline).map((e) => new Tuple2<Hour, num>(
        new Hour.beginning(new TZDateTime.from(e['hourBeginning'], _location)),
        e['mcc']));
  }


  /// Get the hourly dam data by column timeseries, two vectors (a vector of
  /// datetimes and a vector of values).
  /// [[component]] can be one of 'lmp', 'congestion', 'loss'
  Future<Tuple2<List<String>, List<String>>> getHourlyDataColumn(int ptid, String component,
      {Date startDate, Date endDate}) async {

    Stream res = getHourlyData(ptid, component, startDate: startDate, endDate: endDate);
    List hourBeginning = [];
    List comp = [];

    await for (var e in res) {
      hourBeginning.add(new TZDateTime.from(e['hourBeginning'], _location).toString());
      comp.add(e['price']);
    };

    return new Tuple2(hourBeginning, comp);
  }

  /// Workhorse to extract the dam hourly data from the database by component and ptid.
  Stream getHourlyData(int ptid, String component,
      {Date startDate, Date endDate}) {
    List pipeline = [];
    Map match = {
      'ptid': {'\$eq': ptid}
    };
    Map hb = {};
    if (startDate != null) {
      TZDateTime start = new TZDateTime(
          _location, startDate.year, startDate.month, startDate.day);
      hb['\$gte'] = start;
    }
    if (endDate != null) {
      endDate = endDate.add(1);
      TZDateTime end =
      new TZDateTime(_location, endDate.year, endDate.month, endDate.day);
      hb['\$lt'] = end;
    }
    if (hb.isNotEmpty) match['hourBeginning'] = hb;

    Map project = {'_id': 0, 'hourBeginning': 1, 'price': '\$$component'};

    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});

    return coll.aggregateToStream(pipeline);
  }





  /// For the pipeline aggregation queries
  /// start and end are Strings in yyyy-mm-dd format.
  Map _constructMatchClause(List<int> ptids, String start, String end) {
    Map aux = {};
    if (ptids != null) aux['ptid'] = {'\$in': ptids};
    if (start != null) {
      if (!aux.containsKey('localDate')) aux['localDate'] = {};

      aux['localDate']['\$gte'] = start;
    }
    if (end != null) {
      if (!aux.containsKey('localDate')) aux['localDate'] = {};

      aux['localDate']['\$lte'] = end;
    }

    return aux;
  }

  /**
   * Get the low and high limit for the data to define the yScale for plotting.
   * [start] a day in the yyyy-mm-dd format, e.g. '2015-01-01',
   * [end] a day in the yyyy-mm-dd format, e.g. '2015-01-09'.  This is inclusive of end date.
   * db.DA_LMP.aggregate([{$match: {ptid: {$in: [4001, 4000]}}},
   *   {$group: {_id: null, yMin: {$min: '$congestionComponent'}, yMax: {$max: '$congestionComponent'}}}])
   */
  //@ApiMethod(path: 'minmax/{maskedUnitId}')
  //url http://127.0.0.1:8080/dalmp/v1/maskedunitid/60802
  Future<Map> getLimits(List<int> ptids, String start, String end,
      {String frequency: 'hourly'}) {
    List pipeline = [];
    var groupId;
    Map group;
//    String startDate = new DateFormat('yyyy-MM-dd').format(start);
//    String endDate = new DateFormat('yyyy-MM-dd').format(end);

    var match = {'\$match': _constructMatchClause(ptids, start, end)};

    if (frequency == 'daily') {
      groupId = {
        'ptid': '\$ptid',
        'year': {'\$year': '\$hourBeginning'},
        'month': {'\$month': '\$hourBeginning'},
        'day': {'\$dayOfMonth': '\$hourBeginning'}
      };
    } else if (frequency == 'monthly') {
      groupId = {
        'ptid': '\$ptid',
        'year': {'\$year': '\$hourBeginning'},
        'month': {'\$month': '\$hourBeginning'}
      };
    }

    if (frequency != 'hourly') {
      // i need to average it first
      group = {
        '\$group': {
          '_id': groupId,
          'congestionComponent': {'\$avg': '\$congestionComponent'}
        }
      };
    } else {
      // for hourly data calculate the min and max directly
      group = {
        '\$group': {
          '_id': null,
          'yMin': {'\$min': '\$congestionComponent'},
          'yMax': {'\$max': '\$congestionComponent'}
        }
      };
    }
    ;

    pipeline.add(match);
    pipeline.add(group);

    if (frequency != 'hourly') {
      // i need to aggregate further (the days or the months)
      var group2 = {
        '\$group': {
          '_id': null,
          'yMin': {'\$min': '\$congestionComponent'},
          'yMax': {'\$max': '\$congestionComponent'}
        }
      };
      pipeline.add(group2);
    }

    ///print(pipeline);
    return coll.aggregate(pipeline).then((v) {
      ///print(v['result']);
      return v['result'].first;
    });
  }
}
