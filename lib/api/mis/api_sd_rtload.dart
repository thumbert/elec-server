library api.sd_rtload;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

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
  Future<ApiResponse> rtload(
      String assetId, String start, String end) async {
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
          'Ownership Share': {'\$arrayElemAt': ['\$Ownership Share', 0]},
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
  Future<ApiResponse> rtloadAll(
      String start, String end) async {
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
    var pipeline = [
      {
        '\$match': {
          'date': {
            '\$gte': Date.parse(start).toString(),
            '\$lte': Date.parse(end).toString(),
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
          'Ownership Share': {'\$arrayElemAt': ['\$Ownership Share', 0]},
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

  /// Return the monthly MWh for all assetId, all versions.
  /// Start and end are months in yyyy-mm format.
  @ApiMethod(path: 'monthly/start/{start}/end/{end}')
  Future<ApiResponse> monthlyRtLoadAll(String start, String end) async {
    start =  start.replaceAll('-', '');
    end =  end.replaceAll('-', '');
    var startM = Month(int.parse(start.substring(0,4)), int.parse(start.substring(4)));
    var endM = Month(int.parse(end.substring(0,4)), int.parse(end.substring(4)));
    var pipeline = [
      {
        '\$match': {
          'date': {
            '\$gte': startM.startDate.toString(),
            '\$lte': endM.endDate.toString(),
          },
        }
      },
      // sum the hourly values
      {
        '\$project': {
          '_id': 0,
          'month': {'\$substr': ['\$date', 0, 7]},
          'version': {'\$toString': '\$version'},
          'Asset ID': '\$Asset ID',
          'Load Reading': {'\$sum': '\$Load Reading'},
          'Ownership Share': {'\$arrayElemAt': ['\$Ownership Share', 0]},
          'Share of Load Reading': {'\$sum': '\$Share of Load Reading'},
        }
      },
      // sum the daily values inside the month
      {
        '\$group': {
          '_id': {
            'month': '\$month',
            'version': '\$version',
            'Asset ID': '\$Asset ID',
          },
          'Load Reading': {'\$sum': '\$Load Reading'},
          'Ownership Share': {'\$avg': '\$Ownership Share'},
          'Share of Load Reading': {'\$sum': '\$Share of Load Reading'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'month': '\$_id.month',
          'version': '\$_id.version',
          'Asset ID': '\$_id.Asset ID',
          'Load Reading': 1,
          'Ownership Share': 1,
          'Share of Load Reading': 1,
        },
      },
      {
        '\$sort': {
          'month': 1,
          'Asset ID': 1,
        }
      }
    ];
    var res = await coll.aggregateToStream(pipeline).toList();
    return ApiResponse()..result = json.encode(res);
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


  Stream<Map<String,dynamic>> _rtloadQuery(String assetId, String start, String end) {
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

  Future<List<Map<String,dynamic>>> _format(Stream<Map<String,dynamic>> data) async {
    var out = <Map<String,dynamic>>[];
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

  Future<List<Map<String,dynamic>>> _format2(Stream<Map> data) async {
    var out = <Map<String,dynamic>>[];
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
