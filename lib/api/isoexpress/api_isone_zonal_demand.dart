library api.isone_zonal_demand;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';

class ZonalDemand {
  ZonalDemand(this.db) {
    coll = db.collection(collectionName);
  }

  late Db db;
  late DbCollection coll;
  final DateFormat fmt = DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'zonal_demand';

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Return a list of Map elements like this:
    /// ```dart
    /// {
    ///   'hourBeginning': '2017-01-01 00:00:00.000-0500',
    ///   'DA_Demand': 11167.1,
    ///   'RT_Demand': 11810.35,
    ///   'DryBulb': 37,
    ///   'DewPoint': 32,
    /// }
    /// ```
    // router.get('/zone/<zone>/start/<start>/end/<end>', (Request request,
    //     String zone, String start, String end) async {
    //   var aux = await apiGetZonalDemand(zone, start, end);
    //   return Response.ok(json.encode(aux), headers: headers);
    // });

    /// Return a list of Map elements like this:
    /// ```dart
    /// {
    ///   '2017-01-01': <num>[11810.35, ...],
    /// }
    /// ```
    router.get('/market/<market>/zone/<zone>/start/<start>/end/<end>', (Request request,
        String market, String zone, String start, String end) async {
      var aux = await getData(zone, startDate: start, endDate: end, market: market.toUpperCase());
      return Response.ok(json.encode(aux), headers: headers);
    });


    return router;
  }


  /// http://localhost:8080/zonal_demand/v1/zone/isone/start/20170101/end/20170101
  ///
  // Future<List<Map<String, dynamic>>> apiGetZonalDemand(
  //     String zone, String start, String end) async {
  //
  //   var aux = await _getHourlyData(zone, startDate: start, endDate: end);
  //   var out = <Map<String,dynamic>>[];
  //   var keys = [
  //     'hourBeginning',
  //     'DA_Demand',
  //     'RT_Demand',
  //     'DryBulb',
  //     'DewPoint'
  //   ];
  //   for (var e in aux) {
  //     /// each element is a list of 24 hours, prices
  //     for (var i = 0; i < e['hourBeginning'].length; i++) {
  //       out.add(Map.fromIterables(keys, [
  //         TZDateTime.from(e['hourBeginning'][i], _location).toString(),
  //         e['DA_Demand'][i],
  //         e['RT_Demand'][i],
  //         e['DryBulb'][i],
  //         e['DewPoint'][i],
  //       ]));
  //     }
  //   }
  //   return out;
  // }


  /// Return one element for each day
  Future<Map<String,List>> getData(String zone,
      {required String startDate, required String endDate, required String market}) async {
    late String variable;
    if (market.toUpperCase() == 'RT') {
      variable = 'RT_Demand';
    } else if (market.toUpperCase() == 'DA') {
      variable = 'DA_Demand';
    } else {
      throw StateError('Unsupported market "$market" in api_isone_zonal_demand ');
    }

    var project = {
      // '_id': 0,
      // 'zoneName': 0,
      'date': 1,
      variable: 1,
    };

    var pipeline = <Map<String,Object>>[
      {
        '\$match': {
          'zoneName': zone.toUpperCase(),
          'date': {
            '\$lte': Date.parse(endDate).toString(),
            '\$gte': Date.parse(startDate).toString(),
          },
        },
      },
      {
        '\$sort': {
          'date': 1,
        },
      },
      {
        '\$project': project,
      }
    ];
    var xs = await coll.aggregateToStream(pipeline).toList();
    return Map.fromEntries(xs
        .map((e) => MapEntry<String,List>(e['date'], e[variable])));
  }
}
