library api.isoexpress.isone_regulationoffers;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:more/ordering.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import '../../src/utils/api_response.dart';

@ApiClass(name: 'da_regulation_offers', version: 'v1')
class DaRegulationOffers {
  DbCollection coll;
  Location location;
  final fmt = DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  final collectionName = 'da_regulation_offer';
  var ordering;

  DaRegulationOffers(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');

    /// create an ordering by price and assetId to use when sorting the stack
    var natural = Ordering.natural<num>();
    var byPrice = natural.onResultOf<Map>((Map e) => e['price']);
    var byAssetId = natural.onResultOf<Map>((Map e) => e['assetId']);
    ordering = byPrice.compound(byAssetId);
  }

  //http://localhost:8080/da_energy_offers/v1/stack/date/20170701/hourending/16
  /// Return the stack, energy offers sorted.
//  @ApiMethod(path: 'stack/date/{date}/hourending/{hourending}')
//  Future<ApiResponse> getGenerationStack(String date, String hourending) async {
//    var stack = <Map<String, dynamic>>[];
//    var eo = await _getEnergyOffers(date, hourending);
//
//    /// 1) get rid of the unavailable units (some still submit offers!),
//    /// 2) make the must run units have $-150 prices in the first block only.
//    /// 3) some units have MW for a segment > Ecomax.
//    var gEo = groupBy(eo.where((e) => e['Unit Status'] != 'UNAVAILABLE'),
//            (e) => e['assetId']);
//    gEo.keys.forEach((assetId) {
//      var offers = gEo[assetId].cast<Map<String, dynamic>>();
//      if (offers.first['Unit Status'] == 'MUST_RUN') {
//        /// need to sort them just in case ...
//        offers.sort((a, b) => a['price'].compareTo(b['price']));
//        offers.first['price'] = -150;
//      }
//      offers.forEach((Map e) {
//        if (e['quantity'] > e['Economic Maximum'])
//          e['quantity'] = e['Economic Maximum'] / offers.length;
//      });
//      stack.addAll(offers);
//    });
//    ordering.sort(stack);
//    return new ApiResponse()..result = json.encode(stack);
//  }

  //http://localhost:8080/da_regulation_offers/v1/date/20170701/hourending/16
  /// Return the regulation offers (price/quantity pairs) for a given datetime.
  @ApiMethod(path: 'date/{date}/hourending/{hourending}')
  Future<ApiResponse> getRegulationOffers(String date, String hourending) async {
    var data = await _getRegulationOffers(date, hourending);
    return ApiResponse()..result = json.encode(data);
  }

  Future<List<Map<String, dynamic>>> _getRegulationOffers(
      String date, String hourending) async {
    hourending = hourending.padLeft(2, '0');
    var day = Date.parse(date);
    var dt = parseHourEndingStamp(mmddyyyy(day), hourending);
    var hB = TZDateTime.fromMillisecondsSinceEpoch(
        location, dt.millisecondsSinceEpoch)
        .toIso8601String();
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$eq': day.toString(),
        }
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'Masked Asset ID': 1,
        'Unit Status': 1,
        'Economic Maximum': 1,
        'hours': {
          '\$filter': {
            'input': '\$hours',
            'as': 'hour',
            'cond': {
              '\$eq': ['\$\$hour.hourBeginning', hB]
            }
          }
        },
      }
    });
    pipeline.add({'\$unwind': '\$hours'});
    var res = await coll.aggregateToStream(pipeline);

    /// flatten the map in Dart
    var out = <Map<String, dynamic>>[];
    var keys = <String>[
      'assetId',
      'Unit Status',
      'Economic Maximum',
      'price',
      'quantity'
    ];

    await for (var e in res) {
      List prices = e['hours']['price'];
      for (int i = 0; i < prices.length; i++) {
        out.add(new Map.fromIterables(keys, [
          e['Masked Asset ID'],
          e['Unit Status'],
          e['hours']['Economic Maximum'],
          e['hours']['price'][i],
          e['hours']['quantity'][i]
        ]));
      }
    }
    return out;
  }

  //http://localhost:8080/da_regulation_offers/v1/assetId/41406/start/20170701/end/20171001
  /// Get everything for one generator between a start and end date
  @ApiMethod(path: 'assetId/{assetId}/start/{start}/end/{end}')
  Future<ApiResponse> getRegulationOffersForAssetId(
      String assetId, String start, String end) async {
    var pipeline = [
      {
        '\$match': {
          'date': {
            '\$gte': Date.parse(start).toString(),
            '\$lte': Date.parse(end).toString(),
          },
          'Masked Asset ID': {'\$eq': int.parse(assetId)}
        }
      },
      {
        '\$project': {
          '_id': 0,
          'Masked Asset ID': 0,
          'Masked Lead Participant ID': 0,
        }
      },
      {
        '\$sort': {'date': 1}
      },
    ];
    var aux = await coll.aggregateToStream(pipeline).toList();
    return ApiResponse()..result = json.encode(aux);
  }


  /// http://localhost:8080/da_regulation_offers/v1/assets/day/20170301
  /// Get the assets that participated on this day
  @ApiMethod(path: 'assets/day/{day}')
  Future<ApiResponse> assetsByDay(String day) async {
    var query = where.eq('date', Date.parse(day).toString()).excludeFields(
        ['_id']).fields(['Masked Asset ID', 'Masked Lead Participant ID']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  /// http://localhost:8080/da_regulation_offers/v1/assets/participantId/355376/start/20170301/end/20170305
  /// Get all the assets offered by a participant Id between a start and end
  /// date.
  @ApiMethod(path: 'assets/participantId/{participantId}/start/{start}/end/{end}')
  Future<ApiResponse> assetsForParticipant(int participantId,
      String start, String end) async {
    var query = where
        .gte('date', Date.parse(start).toString())
        .lte('date', Date.parse(end).toString())
        .eq('Masked Lead Participant ID', participantId)
        .excludeFields(['_id'])
        .fields(['date', 'Masked Asset ID']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  /// http://localhost:8080/da_energy_offers/v1/ownership/assetId/80076/start/20170501/end/20170801
  /// Check the ownership of an assetId between a start and end date.
  @ApiMethod(path: 'ownership/assetId/{assetId}/start/{start}/end/{end}')
  Future<ApiResponse> assetOwnership(int assetId,
      String start, String end) async {
    var query = where
        .gte('date', Date.parse(start).toString())
        .lte('date', Date.parse(end).toString())
        .eq('Masked Asset ID', assetId)
        .excludeFields(['_id'])
        .fields(['date', 'Masked Asset ID', 'Masked Lead Participant ID']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }
}
