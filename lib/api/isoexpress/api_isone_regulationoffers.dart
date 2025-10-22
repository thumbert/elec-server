import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class DaRegulationOffers {
  late DbCollection coll;
  Location? location;
  final collectionName = 'da_regulation_offer';

  DaRegulationOffers(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/start/<start>/end/<end>',
        (Request request, String start, String end) async {
      var aux = await getRegulationOffers(start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/assetId/<assetId>/start/<start>/end/<end>',
        (Request request, String assetId, String start, String end) async {
      var aux =
          await getRegulationOffersForAssetId(int.parse(assetId), start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/assets/day/<day>', (Request request, String day) async {
      var aux = await assetsByDay(day);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/assets/participantId/<participantId>/start/<start>/end/<end>',
        (Request request, String participantId, String start,
            String end) async {
      var aux =
          await assetsForParticipant(int.parse(participantId), start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get('/ownership/assetId/<assetId>/start/<start>/end/<end>',
        (Request request, String assetId, String start, String end) async {
      var aux = await assetOwnership(int.parse(assetId), start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  //http://localhost:8080/da_energy_offers/v1/start/20170701/end/20170731
  /// Return the regulation offers between two dates
  Future<List<Map<String, dynamic>>> getRegulationOffers(
      String start, String end) async {
    var query = where
        .gte('date', Date.parse(start).toString())
        .lte('date', Date.parse(end).toString())
        .excludeFields(['_id']);
    return coll.find(query).toList();
  }

  //http://localhost:8080/da_regulation_offers/v1/assetId/41406/start/20170701/end/20171001
  /// Get everything for one generator between a start and end date
  Future<List<Map<String, dynamic>>> getRegulationOffersForAssetId(
      int assetId, String start, String end) async {
    var query = where
        .gte('date', Date.parse(start).toString())
        .lte('date', Date.parse(end).toString())
        .eq('Masked Asset ID', assetId)
        .excludeFields(['_id']);
    return coll.find(query).toList();
  }

  /// http://localhost:8080/da_regulation_offers/v1/assets/day/20170301
  /// Get the assets that participated on this day
  Future<List<Map<String, dynamic>>> assetsByDay(String day) async {
    var query = where.eq('date', Date.parse(day).toString()).excludeFields(
        ['_id']).fields(['Masked Asset ID', 'Masked Lead Participant ID']);
    return coll.find(query).toList();
  }

  /// http://localhost:8080/da_regulation_offers/v1/assets/participantId/355376/start/20170301/end/20170305
  /// Get all the assets offered by a participant Id between a start and end
  /// date.
  Future<List<Map<String, dynamic>>> assetsForParticipant(
      int participantId, String start, String end) async {
    var query = where
        .gte('date', Date.parse(start).toString())
        .lte('date', Date.parse(end).toString())
        .eq('Masked Lead Participant ID', participantId)
        .excludeFields(['_id']).fields(['date', 'Masked Asset ID']);
    return coll.find(query).toList();
  }

  /// http://localhost:8080/da_energy_offers/v1/ownership/assetId/80076/start/20170501/end/20170801
  /// Check the ownership of an assetId between a start and end date.
  Future<List<Map<String, dynamic>>> assetOwnership(
      int assetId, String start, String end) async {
    var query = where
        .gte('date', Date.parse(start).toString())
        .lte('date', Date.parse(end).toString())
        .eq('Masked Asset ID', assetId)
        .excludeFields(['_id']).fields(
            ['date', 'Masked Asset ID', 'Masked Lead Participant ID']);
    return coll.find(query).toList();
  }
}
