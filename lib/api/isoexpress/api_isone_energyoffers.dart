library api.isone_energyoffers;

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

@ApiClass(name: 'da_energy_offers', version: 'v1')
class DaEnergyOffers {
  DbCollection coll;
  Location location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'da_energy_offer';
  var ordering;

  DaEnergyOffers(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');

    /// create an ordering by price and assetId to use when sorting the stack
    var natural = Ordering.natural<num>();
    var byPrice = natural.onResultOf<Map>((Map e) => e['price']);
    var byAssetId = natural.onResultOf<Map>((Map e) => e['assetId']);
    ordering = byPrice.compound(byAssetId);
  }

  //http://localhost:8080/da_energy_offers/v1/stack/date/20170701/hourending/16
  @ApiMethod(path: 'stack/date/{date}/hourending/{hourending}')

  /// return the stack, energy offers sorted.
  Future<ApiResponse> getGenerationStack(String date, String hourending) async {
    var stack = <Map<String, dynamic>>[];
    var eo = await _getEnergyOffers(date, hourending);

    /// 1) get rid of the unavailable units (some still submit offers!),
    /// 2) make the must run units have $-150 prices in the first block only.
    /// 3) some units have MW for a segment > Ecomax.
    var gEo = groupBy(eo.where((e) => e['Unit Status'] != 'UNAVAILABLE'),
        (e) => e['assetId']);
    gEo.keys.forEach((assetId) {
      var offers = gEo[assetId].cast<Map<String, dynamic>>();
      if (offers.first['Unit Status'] == 'MUST_RUN') {
        /// need to sort them just in case ...
        offers.sort((a, b) => a['price'].compareTo(b['price']));
        offers.first['price'] = -150;
      }
      offers.forEach((Map e) {
        if (e['quantity'] > e['Economic Maximum'])
          e['quantity'] = e['Economic Maximum'] / offers.length;
      });
      stack.addAll(offers);
    });
    ordering.sort(stack);
    return new ApiResponse()..result = json.encode(stack);
  }

  //http://localhost:8080/da_energy_offers/v1/date/20170701/hourending/16
  @ApiMethod(path: 'date/{date}/hourending/{hourending}')

  /// Return the energy offers (price/quantity pairs) for a given datetime.
  Future<ApiResponse> getEnergyOffers(String date, String hourending) async {
    var data = await _getEnergyOffers(date, hourending);
    return ApiResponse()..result = json.encode(data);
  }

  Future<List<Map<String, dynamic>>> _getEnergyOffers(
      String date, String hourending) async {
    hourending = hourending.padLeft(2, '0');
    Date day = Date.parse(date);
    TZDateTime dt = parseHourEndingStamp(mmddyyyy(day), hourending);
    String hB = TZDateTime.fromMillisecondsSinceEpoch(
            location, dt.millisecondsSinceEpoch)
        .toIso8601String();
    List pipeline = [];
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

  //http://localhost:8080/da_energy_offers/v1/assetId/41406/start/20170701/end/20171001
  @ApiMethod(path: 'assetId/{assetId}/start/{start}/end/{end}')

  /// Get everything for one generator between a start and end date
  Future<ApiResponse> getEnergyOffersForAssetId(
      String assetId, String start, String end) async {
    List pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        },
        'Masked Asset ID': {'\$eq': int.parse(assetId)}
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'Masked Asset ID': 0,
        'Masked Lead Participant ID': 0,
      }
    });
    pipeline.add({
      '\$sort': {'date': 1}
    });
    var aux = await coll.aggregateToStream(pipeline).toList();
    aux.forEach((document) {
      document['hours'] = json.encode(document['hours']);
    });
    return ApiResponse()..result = json.encode(aux);
  }

  //http://localhost:8080/da_energy_offers/v1/daily/variable/Maximum Daily Energy/start/20170701/end/20171001
  @ApiMethod(path: 'daily/variable/{variable}/start/{start}/end/{end}')

  /// Get a variable between a start and end date for all the assets.
  Future<ApiResponse> oneDailyVariable(
      String variable, String start, String end) async {
    List pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$gte': Date.parse(start).toString(),
          '\$lte': Date.parse(end).toString(),
        }
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'date': 1,
        'Masked Asset ID': 1,
        variable: 1,
      }
    });
    pipeline.add({
      '\$sort': {'date': 1}
    });
    var aux = await coll.aggregateToStream(pipeline).toList();
    return ApiResponse()..result = json.encode(aux);
  }

  //http://localhost:8080/da_energy_offers/v1/daily_data/day/20170701
  @ApiMethod(path: 'daily_data/day/{day}')
  Future<ApiResponse> dailyData(String day) async {
    List pipeline = [];
    pipeline.add({
      '\$match': {
        'date': {
          '\$eq': Date.parse(day).toString(),
        }
      }
    });
    pipeline.add({
      '\$project': {
        '_id': 0,
        'date': 1,
        'Masked Asset ID': 1,
        'Must Take Energy': 1,
        'Maximum Daily Energy Available': 1,
        'Economic Maximum': 1,
        'Economic Minimum': 1,
        'Cold Startup Price': 1,
        'Intermediate Startup Price': 1,
        'Hot Startup Price': 1,
        'No Load Price': 1,
        'Unit Status': 1,
        'Claim 10': 1,
        'Claim 30': 1,
      }
    });
    pipeline.add({
      '\$sort': {'date': 1}
    });
    var aux = await coll.aggregateToStream(pipeline).toList();
    return ApiResponse()..result = json.encode(aux);
  }

  /// http://localhost:8080/da_energy_offers/v1/assets/day/20170301
  @ApiMethod(path: 'assets/day/{day}')
  Future<ApiResponse> assetsByDay(String day) async {
    var query = where.eq('date', Date.parse(day).toString()).excludeFields(
        ['_id']).fields(['Masked Asset ID', 'Masked Lead Participant ID']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  /// http://localhost:8080/da_energy_offers/v1/assets/participantId/355376/start/20170301/end/20170305
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



  /// http://localhost:8080/da_energy_offers/v1/lastday
  @ApiMethod(path: 'lastday')
  Future<ApiResponse> lastDay() async {
    var query = where.sortBy('date', descending: true).limit(1);
    var aux = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(aux.first['date']);
  }
}
