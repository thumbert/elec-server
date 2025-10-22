import 'dart:async';
import 'dart:convert';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:table/table.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:dama/dama.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SdRtload {
  late mongo.DbCollection coll;
  late Location location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'sd_rtload';

  SdRtload(mongo.Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/assetId/<assetId>/start/<start>/end/<end>',
        (Request request, String assetId, String start, String end) async {
      var aux = await rtload(assetId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/assetId/<assetId>/start/<start>/end/<end>/csv',
        (Request request, String assetId, String start, String end) async {
      var aux = await rtloadCsv(assetId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/start/<start>/end/<end>/assetIds/<assetIds>/lastSettlement',
        (Request request, String start, String end, String assetIds) async {
      var aux =
          await hourlyRtLoadForAssetIdsLastSettlement(start, end, assetIds);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/daily/assetId/<assetId>/start/<start>/end/<end>',
        (Request request, String assetId, String start, String end) async {
      var aux = await dailyRtLoad(assetId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await rtloadAll(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/daily/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await dailyRtLoadAll(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/monthly/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String start, String end, String settlement) async {
      var aux =
          await monthlyRtLoadSettlement(start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Hourly data, all settlements for one assset id.  Return a list with
  /// elements like this:
  /// ```
  ///{
  ///  'version': '2020-05-06T02:52:38.000Z',
  ///  'hourBeginning': '2020-05-01 00:00:00.000-0400',
  ///  'Load Reading': -588.668,
  ///  'Ownership Share': 80,
  ///  'Share of Load Reading': -470.9344
  ///}
  /// ```
  ///http://127.0.0.1:8080/sd_rtload/v1/assetId/2481/start/20171201/end/20171201
  Future<List<Map<String, dynamic>>> rtload(
      String assetId, String start, String end) async {
    var res = _rtloadQuery(assetId, start, end);
    return _format(res);
  }

  /// Hourly data last settlement for several assset ids aggregated.
  /// Return
  /// ```
  /// {
  ///   "date" : "2013-06-01",
  ///   "Asset ID" : 201,
  ///   "Load Reading" : [ -150, ..., -150 ] }
  ///   "Ownership Share" : [ 10, ..., 10 ] }
  ///   "Share of Load Reading" : [ -15, ..., -15 ] }
  /// ```
  //http://127.0.0.1:8080/sd_rtload/v1/assetId/2481/start/20171201/end/20171201
  // @ApiMethod(path: 'start/{start}/end/{end}/assetIds/{assetIds}/lastSettlement')
  Future<List<Map<String, dynamic>>> hourlyRtLoadForAssetIdsLastSettlement(
      String start, String end, String assetIds) async {
    var ids = assetIds.split(',').map((e) => int.parse(e.trim())).toList();
    var pipeline = [
      {
        '\$match': {
          'date': {
            '\$gte': start.toString(),
            '\$lte': end.toString(),
          },
          'Asset ID': {
            '\$in': ids,
          }
        }
      },
      // sort decreasingly by version
      {
        '\$sort': {
          'date': 1,
          'Asset ID': 1,
          'version': -1,
        }
      },
      // group by date, assetId, then get the last version
      {
        '\$group': {
          '_id': {'date': '\$date', 'Asset ID': '\$Asset ID'},
          'version': {'\$first': '\$version'},
          'Load Reading': {'\$first': '\$Load Reading'},
          'Ownership Share': {'\$first': '\$Ownership Share'},
          'Share of Load Reading': {'\$first': '\$Share of Load Reading'},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'Asset ID': '\$_id.Asset ID',
          'date': '\$_id.date',
          'Load Reading': '\$Load Reading',
          'Ownership Share': '\$Ownership Share',
          'Share of Load Reading': '\$Share of Load Reading',
        }
      },
      {
        '\$sort': {
          'date': 1,
          'Asset ID': 1,
        }
      }
    ];
    return coll.aggregateToStream(pipeline).toList();
  }

  //http://127.0.0.1:8080/sd_rtload/v1/daily/assetId/2481/start/20171201/end/20171201
  /// Return the daily MWh for this assetId, all versions.
  // @ApiMethod(path: 'daily/assetId/{assetId}/start/{start}/end/{end}')
  Future<List<Map<String, dynamic>>> dailyRtLoad(
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
    return coll.aggregateToStream(pipeline).toList();
  }

  //http://127.0.0.1:8080/sd_rtload/v1/start/20171201/end/20171201
  // @ApiMethod(path: 'start/{start}/end/{end}')
  Future<List<Map<String, dynamic>>> rtloadAll(String start, String end) async {
    var pipeline = <Map<String, Object>>[];
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
    return _format2(res);
  }

  //http://127.0.0.1:8080/sd_rtload/v1/daily/start/20171201/end/20171201
  /// Return the daily MWh for all assetId, all versions.
  // @ApiMethod(path: 'daily/start/{start}/end/{end}')
  Future<List<Map<String, dynamic>>> dailyRtLoadAll(
      String start, String end) async {
    var pipeline =
        _pipelineAllAssetsVersionsDaily(Date.parse(start), Date.parse(end));
    return coll.aggregateToStream(pipeline).toList();
  }

  List<Map<String, Object>> _pipelineAllAssetsVersionsDaily(
      Date start, Date end) {
    return <Map<String, Object>>[
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
  // @ApiMethod(path: 'monthly/start/{start}/end/{end}/settlement/{settlement}')
  Future<List<Map<String, dynamic>>> monthlyRtLoadSettlement(
      String start, String end, int settlement) async {
    // Note that you can't do the monthly aggregation on the Mongo side, because
    // the version is different between days and doesn't match the settlement #.
    // Have to use the daily query and aggregate it in dart.
    start = start.replaceAll('-', '');
    end = end.replaceAll('-', '');
    var startM = Month.utc(
        int.parse(start.substring(0, 4)), int.parse(start.substring(4)));
    var endM =
        Month.utc(int.parse(end.substring(0, 4)), int.parse(end.substring(4)));

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
    return flattenMap(aux, ['month', 'Asset ID'])!;
  }

  //http://127.0.0.1:8080/sd_rtload/v1/assetId/1485/start/20171201/end/20171201/csv
  // @ApiMethod(path: 'assetId/{assetId}/start/{start}/end/{end}/csv')
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
    return out as FutureOr<List<String>>;
  }

  Stream<Map<String, dynamic>> _rtloadQuery(
      String assetId, String start, String end) {
    var pipeline = <Map<String, Object>>[];
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

  Future<List<Map<String, dynamic>>> _format2(
      Stream<Map<String, dynamic>> data) async {
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
