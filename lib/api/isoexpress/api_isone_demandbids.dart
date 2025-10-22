import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaDemandBids {
  late DbCollection coll;
  late Location location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'da_demand_bid';

  DaDemandBids(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/stack/date/<date>/hourending/<hourending>',
        (Request request, String date, String hourending) async {
      var aux = await getDemandBidsStack(date, hourending);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/daily/mwh/demandbid/participantId/<participantId>/start/<start>/end/<end>',
        (Request request, String participantId, String start,
            String end) async {
      var aux = await dailyMwhDemandBidByZoneForParticipant(
          participantId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/daily/mwh/demandbid/participantId/<participantId>/ptid/<ptid>/start/<start>/end/<end>',
        (Request request, String participantId, String ptid, String start,
            String end) async {
      var aux = await dailyMwhDemandBidForParticipantZone(
          participantId, ptid, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/daily/mwh/demandbid/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await dailyMWhDemandBid(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/daily/mwh/demandbid/ptid/<ptid>/start/<start>/end/<end>',
        (Request request, String ptid, String start, String end) async {
      var aux = await dailyMWhDemandBidForLoadZone(ptid, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/daily/mwh/demandbid/participant/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux =
          await dailyMwhDemandBidByParticipantForZone(start, end, ptid: null);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/daily/mwh/demandbid/participant/ptid/<ptid>/start/<start>/end/<end>',
        (Request request, String ptid, String start, String end) async {
      var aux = await dailyMwhDemandBidByParticipantForZone(start, end,
          ptid: int.parse(ptid));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/daily/mwh/incdec/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await dailyMwhIncDec(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/daily/mwh/incdec/byparticipant/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await dailyMwhIncDecByParticipant(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  //http://localhost:8080/da_demand_bids/v1/stack/date/20170701/hourending/16
  /// Return the stack (price/quantity pairs) for a given datetime.
  Future<List<Map<String, dynamic>>> getDemandBidsStack(
      String date, String hourending) async {
    if (hourending.length == 1) hourending = hourending.padLeft(2, '0');
    var day = Date.parse(date);
    var _dt = parseHourEndingStamp(mmddyyyy(day), hourending);
    var dt = TZDateTime.fromMillisecondsSinceEpoch(
            location, _dt.millisecondsSinceEpoch)
        .toIso8601String();

    var pipeline = <Map<String, Object>>[];
    pipeline.add({
      '\$match': {
        'date': {
          '\$eq': day.toString(),
        },
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'Masked Location ID': 1,
        'Masked Lead Participant ID': 1,
        'Bid Type': 1,
        'hours': {
          '\$filter': {
            'input': '\$hours',
            'as': 'hour',
            'cond': {
              '\$eq': ['\$\$hour.hourBeginning', dt]
            }
          }
        },
      }
    });
    pipeline.add({'\$unwind': '\$hours'});
    var res = await coll.aggregateToStream(pipeline).toList();

    /// flatten the map in Dart
    var out = <Map<String, dynamic>>[];
    var keys = ['locationId', 'participantId', 'bidType', 'price', 'quantity'];
    for (var e in res) {
      List? prices = e['hours']['price'];
      var qty = e['hours']['quantity'] as List;
      prices ??= List.filled(qty.length, 999);
      for (var i = 0; i < prices.length; i++) {
        out.add(Map.fromIterables(keys, [
          e['Masked Location ID'],
          e['Masked Lead Participant ID'],
          e['Bid Type'],
          prices[i],
          qty[i],
        ]));
      }
    }
    return out;
  }

  //http://localhost:8080/da_demand_bids/v1/daily/mwh/participantId/206845/start/20170701/end/20171001
  /// Get daily total MWh zonal demand bids by participant between a start
  /// and end date, return all available zones.
  Future<List<Map<String, dynamic>>> dailyMwhDemandBidByZoneForParticipant(
      String participantId, String start, String end) async {
    var pipeline = <Map<String, Object>>[];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Masked Lead Participant ID': {'\$eq': int.parse(participantId)},
        'Location Type': {'\$eq': 'LOAD ZONE'}
      }
    });
    pipeline.add({
      '\$unwind': '\$hours',
    });
    pipeline.add({
      '\$unwind': '\$hours.quantity',
    });
    pipeline.add({
      '\$group': {
        '_id': {
          'locationId': '\$Masked Location ID',
          'date': '\$date',
        },
        'MWh': {'\$sum': '\$hours.quantity'},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'locationId': '\$_id.locationId',
        //'bidType': '\$_id.bidType',
        'date': '\$_id.date',
        'MWh': '\$MWh',
      }
    });
    return coll.aggregateToStream(pipeline).toList();
  }

  //http://localhost:8080/da_demand_bids/v1/mwh/participantId/206845/ptid/4004/start/20170701/end/20171001
  /// Get daily total MWh zonal demand bids by day for a participant and zone id
  /// between a start and end date,
  Future<List<Map<String, dynamic>>> dailyMwhDemandBidForParticipantZone(
      String participantId, String ptid, String start, String end) async {
    var pipeline = <Map<String, Object>>[];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Masked Lead Participant ID': {'\$eq': int.parse(participantId)},
        'Location Type': {'\$eq': 'LOAD ZONE'},
        'Masked Location ID': {'\$eq': _unmaskedLocations[int.parse(ptid)]}
      }
    });
    pipeline.add({
      '\$unwind': '\$hours',
    });
    pipeline.add({
      '\$unwind': '\$hours.quantity',
    });
    pipeline.add({
      '\$group': {
        '_id': {
          'locationId': '\$Masked Location ID',
          'date': '\$date',
        },
        'MWh': {'\$sum': '\$hours.quantity'},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'locationId': '\$_id.locationId',
        //'bidType': '\$_id.bidType',
        'date': '\$_id.date',
        'MWh': '\$MWh',
      }
    });
    return coll.aggregateToStream(pipeline).toList();
  }

  /// Get the total daily MWh demand bids for all participants between a start
  /// and end date for this zone.
  Future<List<Map<String, dynamic>>> dailyMWhDemandBid(
      String start, String end) async {
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Bid Type': {
          '\$in': ['FIXED', 'PRICE']
        },
      }
    });
    pipeline.add({
      '\$unwind': '\$hours',
    });
    pipeline.add({
      '\$unwind': '\$hours.quantity',
    });
    pipeline.add({
      '\$group': {
        '_id': {
          'date': '\$date',
          'Bid Type': '\$Bid Type',
        },
        'MWh': {'\$sum': '\$hours.quantity'},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'date': '\$_id.date',
        'Bid Type': '\$_id.Bid Type',
        'MWh': '\$MWh',
      }
    });
    return coll
        .aggregateToStream(pipeline as List<Map<String, Object>>)
        .toList();
  }

  //http://localhost:8080/da_demand_bids/v1/mwh/ptid/4004/start/20170701/end/20171001
  /// Get the total daily MWh demand bids for all participants between a start
  /// and end date for this zone.
  Future<List<Map<String, dynamic>>> dailyMWhDemandBidForLoadZone(
      String ptid, String start, String end) async {
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Location Type': {'\$eq': 'LOAD ZONE'},
        'Masked Location ID': {'\$eq': _unmaskedLocations[int.parse(ptid)]}
      }
    });
    pipeline.add({
      '\$unwind': '\$hours',
    });
    pipeline.add({
      '\$unwind': '\$hours.quantity',
    });
    pipeline.add({
      '\$group': {
        '_id': {
          'locationId': '\$Masked Location ID',
          'date': '\$date',
        },
        'MWh': {'\$sum': '\$hours.quantity'},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'locationId': '\$_id.locationId',
        'date': '\$_id.date',
        'MWh': '\$MWh',
      }
    });
    return coll
        .aggregateToStream(pipeline as List<Map<String, Object>>)
        .toList();
  }

  //http://localhost:8080/da_demand_bids/v1/mwh/participant/start/20170701/end/20171001
  /// Get total daily MWh demand bids by participant between a start and end date.
  /// If [ptid] == null, all zones.  If [ptid] = 4004, get CT only, etc.
  Future<List<Map<String, dynamic>>> dailyMwhDemandBidByParticipantForZone(
      String start, String end,
      {int? ptid}) async {
    var pipeline = <Map<String, Object>>[];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Location Type': {'\$eq': 'LOAD ZONE'},
        'Bid Type': {
          '\$in': ['FIXED', 'PRICE']
        },
        if (ptid != null)
          'Masked Location ID': {'\$eq': _unmaskedLocations[ptid]},
      }
    });
    pipeline.add({
      '\$unwind': '\$hours',
    });
    pipeline.add({
      '\$unwind': '\$hours.quantity',
    });
    pipeline.add({
      '\$group': {
        '_id': {
          'participantId': '\$Masked Lead Participant ID',
          'date': '\$date',
        },
        'MWh': {'\$sum': '\$hours.quantity'},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'participantId': '\$_id.participantId',
        'date': '\$_id.date',
        'MWh': '\$MWh',
      }
    });
    return coll.aggregateToStream(pipeline).toList();
  }

  /// Get total daily MWh demand bids by participant between a start and end date.
  /// If [ptid] == null, all zones.  If [ptid] = 4004, get CT only, etc.
  ///
  Future<List<Map<String, dynamic>>> monthlyMwhDemandBidByParticipantForZone(
      String startMonth, String endMonth,
      {int? ptid}) async {
    var pipeline = <Map<String, Object>>[];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Month.parse(startMonth).startDate.toString(),
          '\$lte': Month.parse(endMonth).endDate.toString(),
        },
        'Location Type': {'\$eq': 'LOAD ZONE'},
        'Bid Type': {
          '\$in': ['FIXED', 'PRICE']
        },
        if (ptid != null)
          'Masked Location ID': {'\$eq': _unmaskedLocations[ptid]},
      }
    });
    pipeline.add({
      '\$unwind': '\$hours',
    });
    pipeline.add({
      '\$unwind': '\$hours.quantity',
    });
    pipeline.add({
      '\$group': {
        '_id': {
          'participantId': '\$Masked Lead Participant ID',
          'month': {
            '\$substr': ['\$date', 0, 7]
          },
        },
        'MWh': {'\$sum': '\$hours.quantity'},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'participantId': '\$_id.participantId',
        'month': '\$_id.month',
        'MWh': '\$MWh',
      }
    });
    return coll.aggregateToStream(pipeline).toList();
  }

  /// Get total daily MWh of inc/dec between a start and end date.
  Future<List<Map<String, dynamic>>> dailyMwhIncDec(
      String start, String end) async {
    var pipeline = <Map<String, Object>>[];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Bid Type': {
          '\$in': ['DEC', 'INC']
        }
      }
    });
    pipeline.add({
      '\$unwind': '\$hours',
    });
    pipeline.add({
      '\$unwind': '\$hours.quantity',
    });
    pipeline.add({
      '\$group': {
        '_id': {
          'date': '\$date',
          'Bid Type': '\$Bid Type',
        },
        'MWh': {'\$sum': '\$hours.quantity'},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'date': '\$_id.date',
        'Bid Type': '\$_id.Bid Type',
        'MWh': '\$MWh',
      }
    });
    return coll.aggregateToStream(pipeline).toList();
  }

  /// Get total daily MWh demand bids by participant between a start and end date.
  Future<List<Map<String, dynamic>>> dailyMwhIncDecByParticipant(
      String start, String end) async {
    var pipeline = <Map<String, Object>>[];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Location Type': {'\$eq': 'LOAD ZONE'},
        'Bid Type': {
          '\$in': ['INC', 'DEC']
        }
      }
    });
    pipeline.add({
      '\$unwind': '\$hours',
    });
    pipeline.add({
      '\$unwind': '\$hours.quantity',
    });
    pipeline.add({
      '\$group': {
        '_id': {
          'participantId': '\$Masked Lead Participant ID',
          'date': '\$date',
          'Bid Type': '\$Bid Type',
        },
        'MWh': {'\$sum': '\$hours.quantity'},
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'participantId': '\$_id.participantId',
        'date': '\$_id.date',
        'Bid Type': '\$_id.Bid Type',
        'MWh': '\$MWh',
      }
    });
    return coll.aggregateToStream(pipeline).toList();
  }
}

/// the zones
Map<int, int> _unmaskedLocations = {
  4001: 67184,
  4002: 39271,
  4003: 80396,
  4004: 28934,
  4005: 89933,
  4006: 70291,
  4007: 41756,
  4008: 37894,
};
