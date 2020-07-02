library api.sd_rtload;

import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:rpc/rpc.dart';
import 'package:table/table.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:tuple/tuple.dart';
import 'package:dama/dama.dart';

@ApiClass(name: 'sd_rtload', version: 'v1')
class SdRtload {
  mongo.DbCollection coll;
  Location location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'sd_rtload';

  SdRtload(mongo.Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
  }

  //http://127.0.0.1:8080/sd_rtload/v1/assetId/2481/start/20171201/end/20171201
  @ApiMethod(path: 'assetId/{assetId}/start/{start}/end/{end}')
  Future<ApiResponse> rtload(String assetId, String start, String end) async {
    var res = _rtloadQuery(assetId, start, end);
    var out = await _format(res);
    return ApiResponse()..result = json.encode(out);
  }

  //http://127.0.0.1:8080/sd_rtload/v1/daily/assetId/2481/start/20171201/end/20171201
  /// Return the daily MWh for this assetId, all versions.
  @ApiMethod(path: 'daily/assetId/{assetId}/start/{start}/end/{end}')
  Future<ApiResponse> dailyRtLoad(
      String assetId, String start, String end) async {
    var pipeline = [
      {
        '\$match': {
          'date': {
            '\$gte': Date.parse(start).toString(),
            '\$lte': Date.parse(end).toString(),
          },
          'Asset ID': {'\$eq': int.parse(assetId)},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$date',
          'version': {'\$toString': '\$version'},
          'Load Reading': {'\$sum': '\$Load Reading'},
          'Ownership Share': {
            '\$arrayElemAt': ['\$Ownership Share', 0]
          },
          'Share of Load Reading': {'\$sum': '\$Share of Load Reading'},
        }
      },
      {
        '\$sort': {
          'date': 1,
        }
      }
    ];
    var res = await coll.aggregateToStream(pipeline).toList();
    return ApiResponse()..result = json.encode(res);
  }

  //http://127.0.0.1:8080/sd_rtload/v1/start/20171201/end/20171201
  @ApiMethod(path: 'start/{start}/end/{end}')
  Future<ApiResponse> rtloadAll(String start, String end) async {
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
      }
    });
    var res = coll.aggregateToStream(pipeline);
    var out = await _format2(res);
    return ApiResponse()..result = json.encode(out);
  }

  //http://127.0.0.1:8080/sd_rtload/v1/daily/start/20171201/end/20171201
  /// Return the daily MWh for all assetId, all versions.
  @ApiMethod(path: 'daily/start/{start}/end/{end}')
  Future<ApiResponse> dailyRtLoadAll(String start, String end) async {
    var pipeline =
        _pipelineAllAssetsVersionsDaily(Date.parse(start), Date.parse(end));
    var res = await coll.aggregateToStream(pipeline).toList();
    return ApiResponse()..result = json.encode(res);
  }

  List<Map<String, dynamic>> _pipelineAllAssetsVersionsDaily(
      Date start, Date end) {
    return [
      {
        '\$match': {
          'date': {
            '\$gte': start.toString(),
            '\$lte': end.toString(),
          },
        }
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$date',
          'version': {'\$toString': '\$version'},
          'Asset ID': '\$Asset ID',
          'Load Reading': {'\$sum': '\$Load Reading'},
          'Ownership Share': {
            '\$arrayElemAt': ['\$Ownership Share', 0]
          },
          'Share of Load Reading': {'\$sum': '\$Share of Load Reading'},
        }
      },
      {
        '\$sort': {
          'date': 1,
        }
      }
    ];
  }

  /// Return the monthly MWh for all assetId, all versions.
  /// Start and end are months in yyyy-mm format.
  @ApiMethod(path: 'monthly/start/{start}/end/{end}/settlement/{settlement}')
  Future<ApiResponse> monthlyRtLoadSettlement(
      String start, String end, int settlement) async {
    // Note that you can't do the monthly aggregation on the Mongo side, because
    // the version is different between days and doesn't match the settlement #.
    // Have to use the daily query and aggregate it in dart.
    start = start.replaceAll('-', '');
    end = end.replaceAll('-', '');
    var startM =
        Month(int.parse(start.substring(0, 4)), int.parse(start.substring(4)));
    var endM =
        Month(int.parse(end.substring(0, 4)), int.parse(end.substring(4)));

    var pipeline =
        _pipelineAllAssetsVersionsDaily(startM.startDate, endM.endDate);
    var data = await coll.aggregateToStream(pipeline).toList();
    var res = getNthSettlement(data, (e) => Tuple2(e['date'], e['Asset ID']),
        n: settlement);

    var nest = Nest()
      ..key((e) => (e['date'] as String).substring(0, 7))
      ..key((e) => e['Asset ID'])
      ..rollup((List xs) => {
            'Load Reading': sum(xs.map((e) => e['Load Reading'])),
            'Ownership Share': xs.first['Ownership Share'],
            'Share of Load Reading':
                sum(xs.map((e) => e['Share of Load Reading'])),
          });

    var aux = nest.map(res);
    var out = flattenMap(aux, ['month', 'Asset ID']);
    return ApiResponse()..result = json.encode(out);
  }

  //http://127.0.0.1:8080/sd_rtload/v1/assetId/1485/start/20171201/end/20171201/csv
  @ApiMethod(path: 'assetId/{assetId}/start/{start}/end/{end}/csv')
  Future<List<String>> rtloadCsv(
      String assetId, String start, String end) async {
    var res = _rtloadQuery(assetId, start, end);
    var out = [];
    out.add(
        '"version","hourBeginning","Load Reading","Ownership Share","Share of Load Reading"');
    await for (Map e in res) {
      List hours = e['hourBeginning'];
      for (var i = 0; i < hours.length; i++) {
        var sb = StringBuffer();
        sb.write('"');
        sb.write((e['version'] as DateTime).toIso8601String());
        sb.write('",');
        sb.write('"');
        sb.write(TZDateTime.from(e['hourBeginning'][i], location).toString());
        sb.write('",');
        sb.write(e['Load Reading'][i]);
        sb.write(',');
        sb.write(e['Ownership Share'][i]);
        sb.write(',');
        sb.write(e['Share of Load Reading'][i]);
        //sb.write('\n');
        out.add(sb.toString());
      }
    }
    return out;
  }

  Stream<Map<String, dynamic>> _rtloadQuery(
      String assetId, String start, String end) {
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Asset ID': {'\$eq': int.parse(assetId)},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
      }
    });
    return coll.aggregateToStream(pipeline);
  }

  Future<List<Map<String, dynamic>>> _format(
      Stream<Map<String, dynamic>> data) async {
    var out = <Map<String, dynamic>>[];
    var keys = <String>[
      'version',
      'hourBeginning',
      'Load Reading',
      'Ownership Share',
      'Share of Load Reading'
    ];
    await for (Map e in data) {
      List hours = e['hourBeginning'];
      for (var i = 0; i < hours.length; i++) {
        out.add(Map.fromIterables(keys, [
          (e['version'] as DateTime).toUtc().toIso8601String(),
          TZDateTime.from(e['hourBeginning'][i], location).toString(),
          e['Load Reading'][i],
          e['Ownership Share'][i],
          e['Share of Load Reading'][i],
        ]));
      }
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _format2(Stream<Map> data) async {
    var out = <Map<String, dynamic>>[];
    var keys = <String>[
      'version',
      'hourBeginning',
      'Asset ID',
      'Load Reading',
      'Ownership Share',
      'Share of Load Reading'
    ];
    await for (Map e in data) {
      List hours = e['hourBeginning'];
      for (var i = 0; i < hours.length; i++) {
        out.add(Map.fromIterables(keys, [
          (e['version'] as DateTime).toUtc().toIso8601String(),
          TZDateTime.from(e['hourBeginning'][i], location).toString(),
          e['Asset ID'],
          e['Load Reading'][i],
          e['Ownership Share'][i],
          e['Share of Load Reading'][i],
        ]));
      }
    }
    return out;
  }
}
