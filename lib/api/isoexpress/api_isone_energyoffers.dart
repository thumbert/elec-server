// library api.isone_energyoffers;
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:collection/collection.dart';
// import 'package:mongo_dart/mongo_dart.dart';
// import 'package:timezone/timezone.dart';
// import 'package:intl/intl.dart';
// import 'package:more/ordering.dart';
// import 'package:date/date.dart';
// import 'package:elec_server/src/utils/iso_timestamp.dart';
// //import '../../src/utils/api_response.dart';
// import 'package:shelf/shelf.dart';
// import 'package:shelf_router/shelf_router.dart';
//
// class DaEnergyOffers {
//   late DbCollection coll;
//   late Location location;
//   final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
//   String collectionName = 'da_energy_offer';
//   late Ordering ordering;
//
//   DaEnergyOffers(Db db) {
//     coll = db.collection(collectionName);
//     location = getLocation('America/New_York');
//
//     /// create an ordering by price and assetId to use when sorting the stack
//     var natural = Ordering.natural<num>();
//     var byPrice = natural.onResultOf<Map>((Map e) => e['price']);
//     var byAssetId = natural.onResultOf<Map>((Map e) => e['assetId']);
//     ordering = byPrice.compound(byAssetId);
//   }
//
//   final headers = {
//     'Content-Type': 'application/json',
//   };
//
//   Router get router {
//     final router = Router();
//
//     /// return the stack, energy offers for one date, hour.
//     ///http://localhost:8080/da_energy_offers/v1/stack/date/20170701/hourending/16
//     router.get('/stack/date/<date>/hourending/<hourending>',
//         (Request request, String date, String hourEnding) async {
//       var aux = await getGenerationStack(date, hourEnding);
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     /// return the energy offers for one date, hour.
//     ///http://localhost:8080/da_energy_offers/v1/date/20170701/hourending/16
//     router.get('/date/<date>/hourending/<hourending>',
//         (Request request, String date, String hourEnding) async {
//       var aux = await _getEnergyOffers(date, hourEnding);
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     /// Return the energy offers for one assetId, date, hour.
//     /// http://localhost:8080/da_energy_offers/v1/assetId/41406/start/20170701/end/20171001
//     router.get('/assetId/<assetId>/start/<start>/end/<end>',
//         (Request request, String assetId, String start, String end) async {
//       var aux = await getEnergyOffersForAssetId(assetId, start, end);
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     /// Get a variable between a start and end date for all the assets.
//     /// http://localhost:8080/da_energy_offers/v1/daily/variable/Maximum Daily Energy/start/20170701/end/20171001
//     router.get('/daily/variable/<variable>/start/<start>/end/<end>',
//         (Request request, String variable, String start, String end) async {
//       variable = Uri.encodeComponent(variable);
//       var aux = await oneDailyVariable(variable, start, end);
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     /// Get daily data for all assets, for one day
//     /// http://localhost:8080/da_energy_offers/v1/daily_data/day/20170701
//     router.get('/daily_data/day/<day>', (Request request, String day) async {
//       var aux = await dailyData(day);
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     /// http://localhost:8080/da_energy_offers/v1/assets/day/20170301
//     router.get('/assets/day/<day>', (Request request, String day) async {
//       var aux = await assetsByDay(day);
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     /// http://localhost:8080/da_energy_offers/v1/assets/participantId/355376/start/20170301/end/20170305
//     router.get('/assets/participantId/<participantId>/start/<start>/end/<end>',
//         (Request request, String participantId, String start,
//             String end) async {
//       var aux =
//           await assetsForParticipant(int.parse(participantId), start, end);
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     /// http://localhost:8080/da_energy_offers/v1/ownership/assetId/80076/start/20170501/end/20170801
//     router.get('/ownership/assetId/<assetId>/start/<start>/end/<end>',
//         (Request request, String assetId, String start, String end) async {
//       var aux = await assetOwnership(int.parse(assetId), start, end);
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     /// http://localhost:8080/da_energy_offers/v1/lastday
//     router.get('/lastday', (Request request) async {
//       var aux = await lastDay();
//       return Response.ok(json.encode(aux), headers: headers);
//     });
//
//     return router;
//   }
//
//   /// return the stack, energy offers sorted.
//   Future<List<Map<String, dynamic>>> getGenerationStack(
//       String date, String hourEnding) async {
//     var stack = <Map<String, dynamic>>[];
//     var eo = await _getEnergyOffers(date, hourEnding);
//
//     /// 1) get rid of the unavailable units (some still submit offers!),
//     /// 2) make the must run units have $-150 prices in the first block only.
//     /// 3) some units have MW for a segment > Ecomax.
//     var gEo = groupBy(eo.where((e) => e['Unit Status'] != 'UNAVAILABLE'),
//         (dynamic e) => e['assetId']);
//     for (var assetId in gEo.keys) {
//       var offers = gEo[assetId]!.cast<Map<String, dynamic>>();
//       if (offers.first['Unit Status'] == 'MUST_RUN') {
//         /// need to sort them just in case ...
//         offers.sort((a, b) => a['price'].compareTo(b['price']));
//         offers.first['price'] = -150;
//       }
//       for (var e in offers) {
//         if (e['quantity'] > e['Economic Maximum']) {
//           e['quantity'] = e['Economic Maximum'] / offers.length;
//         }
//       }
//       stack.addAll(offers);
//     }
//     ordering.sort(stack);
//     return stack;
//   }
//
//   /// Return the energy offers (price/quantity pairs) for a given datetime.
//   Future<List<Map<String, dynamic>>> getEnergyOffers(
//       String date, String hourending) async {
//     return _getEnergyOffers(date, hourending);
//   }
//
//   Future<List<Map<String, dynamic>>> _getEnergyOffers(
//       String date, String hourending) async {
//     hourending = hourending.padLeft(2, '0');
//     var day = Date.parse(date);
//     var dt = parseHourEndingStamp(mmddyyyy(day), hourending);
//     var hB = TZDateTime.fromMillisecondsSinceEpoch(
//             location, dt.millisecondsSinceEpoch)
//         .toIso8601String();
//     var pipeline = <Map<String, Object>>[];
//     pipeline.add({
//       '\$match': {
//         'date': {
//           '\$eq': day.toString(),
//         }
//       }
//     });
//     pipeline.add({
//       '\$project': {
//         '_id': 0,
//         'Masked Asset ID': 1,
//         'Unit Status': 1,
//         'Economic Maximum': 1,
//         'hours': {
//           '\$filter': {
//             'input': '\$hours',
//             'as': 'hour',
//             'cond': {
//               '\$eq': ['\$\$hour.hourBeginning', hB]
//             }
//           }
//         },
//       }
//     });
//     pipeline.add({'\$unwind': '\$hours'});
//     var res = await coll.aggregateToStream(pipeline).toList();
//
//     /// flatten the map in Dart
//     var out = <Map<String, dynamic>>[];
//     var keys = <String>[
//       'assetId',
//       'Unit Status',
//       'Economic Maximum',
//       'price',
//       'quantity'
//     ];
//
//     for (var e in res) {
//       List prices = e['hours']['price'];
//       for (var i = 0; i < prices.length; i++) {
//         out.add(Map.fromIterables(keys, [
//           e['Masked Asset ID'],
//           e['Unit Status'],
//           e['hours']['Economic Maximum'],
//           e['hours']['price'][i],
//           e['hours']['quantity'][i]
//         ]));
//       }
//     }
//     return out;
//   }
//
//   /// Get everything for one generator between a start and end date
//   Future<List<Map<String, dynamic>>> getEnergyOffersForAssetId(
//       String assetId, String start, String end) async {
//     var pipeline = <Map<String, Object>>[];
//     pipeline.add({
//       '\$match': {
//         'date': {
//           '\$gte': Date.parse(start).toString(),
//           '\$lte': Date.parse(end).toString(),
//         },
//         'Masked Asset ID': {'\$eq': int.parse(assetId)}
//       }
//     });
//     pipeline.add({
//       '\$project': {
//         '_id': 0,
//         'Masked Asset ID': 0,
//         'Masked Lead Participant ID': 0,
//       }
//     });
//     pipeline.add({
//       '\$sort': {'date': 1}
//     });
//     var aux = await coll.aggregateToStream(pipeline).toList();
//     for (var document in aux) {
//       document['hours'] = json.encode(document['hours']);
//     }
//     return aux;
//   }
//
//   /// Get a variable between a start and end date for all the assets.
//   Future<List<Map<String, dynamic>>> oneDailyVariable(
//       String variable, String start, String end) async {
//     var pipeline = <Map<String, Object>>[];
//     pipeline.add({
//       '\$match': {
//         'date': {
//           '\$gte': Date.parse(start).toString(),
//           '\$lte': Date.parse(end).toString(),
//         }
//       }
//     });
//     pipeline.add({
//       '\$project': {
//         '_id': 0,
//         'date': 1,
//         'Masked Asset ID': 1,
//         variable: 1,
//       }
//     });
//     pipeline.add({
//       '\$sort': {'date': 1}
//     });
//     var aux = await coll.aggregateToStream(pipeline).toList();
//     return aux;
//   }
//
//   Future<List<Map<String, dynamic>>> dailyData(String day) async {
//     var pipeline = <Map<String, Object>>[];
//     pipeline.add({
//       '\$match': {
//         'date': {
//           '\$eq': Date.parse(day).toString(),
//         }
//       }
//     });
//     pipeline.add({
//       '\$project': {
//         '_id': 0,
//         'date': 1,
//         'Masked Asset ID': 1,
//         'Must Take Energy': 1,
//         'Maximum Daily Energy Available': 1,
//         'Economic Maximum': 1,
//         'Economic Minimum': 1,
//         'Cold Startup Price': 1,
//         'Intermediate Startup Price': 1,
//         'Hot Startup Price': 1,
//         'No Load Price': 1,
//         'Unit Status': 1,
//         'Claim 10': 1,
//         'Claim 30': 1,
//       }
//     });
//     pipeline.add({
//       '\$sort': {'date': 1}
//     });
//     var aux = await coll.aggregateToStream(pipeline).toList();
//     return aux;
//   }
//
//   Future<List<Map<String, dynamic>>> assetsByDay(String day) async {
//     var query = where.eq('date', Date.parse(day).toString()).excludeFields(
//         ['_id']).fields(['Masked Asset ID', 'Masked Lead Participant ID']);
//     var res = await coll.find(query).toList();
//     return res;
//   }
//
//   Future<List<Map<String, dynamic>>> assetsForParticipant(
//       int participantId, String start, String end) async {
//     var query = where
//         .gte('date', Date.parse(start).toString())
//         .lte('date', Date.parse(end).toString())
//         .eq('Masked Lead Participant ID', participantId)
//         .excludeFields(['_id']).fields(['date', 'Masked Asset ID']);
//     var res = await coll.find(query).toList();
//     return res;
//   }
//
//   Future<List<Map<String, dynamic>>> assetOwnership(
//       int assetId, String start, String end) async {
//     var query = where
//         .gte('date', Date.parse(start).toString())
//         .lte('date', Date.parse(end).toString())
//         .eq('Masked Asset ID', assetId)
//         .excludeFields(['_id']).fields(
//             ['date', 'Masked Asset ID', 'Masked Lead Participant ID']);
//     var res = await coll.find(query).toList();
//     return res;
//   }
//
//   Future<String> lastDay() async {
//     var query = where.sortBy('date', descending: true).limit(1);
//     var aux = (await coll.find(query).toList()).first;
//     return aux['date'] as String;
//   }
// }
