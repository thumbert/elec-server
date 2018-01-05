library api.isone_demandbids;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

@ApiClass(name: 'da_demand_bids', version: 'v1')
class DaDemandBids {
  DbCollection coll;
  Location location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'da_demand_bid';

  DaDemandBids(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
  }

  //http://localhost:8080/da_demand_bid/v1/stack/date/20170701/hourending/16
  @ApiMethod(path: 'stack/date/{date}/hourending/{hourending}')

  /// Return the stack (price/quantity pairs) for a given datetime.
  Future<List<Map<String, String>>> getAggregateBids(
      String date, String hourending) async {
    if (hourending.length == 1) hourending = hourending.padLeft(2, '0');
    Date day = Date.parse(date);
    TZDateTime dt = parseHourEndingStamp(mmddyyyy(day), hourending);
    List pipeline = [];
    Map match = {
      'date': {
        '\$eq': day.toString(),
      }
    };
    Map project = {
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
    };
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    pipeline.add({'\$unwind': '\$hours'});
    var res = coll.aggregateToStream(pipeline);

    /// flatten the map in Dart
    List out = [];
    List keys = ['locationId', 'participantId', 'bidType', 'price', 'quantity'];
    await for (Map e in res) {
      List prices = e['hours']['price'];
      for (int i = 0; i < prices.length; i++) {
        out.add(new Map.fromIterables(keys, [
          e['Masked Location ID'],
          e['Masked Lead Participant ID'],
          e['Bid Type'],
          e['hours']['price'][i],
          e['hours']['quantity'][i]
        ]));
      }
    }
    return out;
  }

  //http://localhost:8080/da_demand_bids/v1/participantId/206845/start/20170701/end/20171001
  @ApiMethod(path: 'mwh/participantId/{participantId}/start/{start}/end/{end}')

  /// Get total MWh zonal demand bids by participant between a start and end date.
  Future<List<Map<String, String>>> mwhByDayParticipantLoadZone(
      String participantId, String start, String end) async {
    List pipeline = [];
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

  //http://localhost:8080/da_demand_bids/v1/mwh/participant/start/20170701/end/20171001
  @ApiMethod(path: 'mwh/participant/start/{start}/end/{end}')
  /// Get total MWh demand bids by participant between a start and end date.
  Future<List<Map<String, String>>> marketShare(
      String start, String end) async {
    List pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Location Type': {'\$eq': 'LOAD ZONE'},
        'Bid Type': {'\$in': ['FIXED', 'PRICE']}
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


}
