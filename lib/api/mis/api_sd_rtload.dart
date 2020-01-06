library api.sd_rtload;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'sd_rtload', version: 'v1')
class SdRtload {
  DbCollection coll;
  Location location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'sd_rtload';

  SdRtload(Db db) {
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
