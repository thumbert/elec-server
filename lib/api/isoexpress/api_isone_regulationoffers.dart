library api.isoexpress.isone_regulationoffers;


import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'da_regulation_offers', version: 'v1')
class DaRegulationOffers {
  DbCollection coll;
  Location location;
  final collectionName = 'da_regulation_offer';

  DaRegulationOffers(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
  }

  //http://localhost:8080/da_energy_offers/v1/start/20170701/end/20170731
  /// Return the regulation offers between two dates
  @ApiMethod(path: 'start/{start}/end/{end}')
  Future<ApiResponse> getRegulationOffers(String start, String end) async {
    var query = where
        .gte('date', Date.parse(start).toString())
        .lte('date', Date.parse(end).toString())
        .excludeFields(['_id']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  //http://localhost:8080/da_regulation_offers/v1/assetId/41406/start/20170701/end/20171001
  /// Get everything for one generator between a start and end date
  @ApiMethod(path: 'assetId/{assetId}/start/{start}/end/{end}')
  Future<ApiResponse> getRegulationOffersForAssetId(
      int assetId, String start, String end) async {
    var query = where
        .gte('date', Date.parse(start).toString())
        .lte('date', Date.parse(end).toString())
        .eq('Masked Asset ID', assetId)
        .excludeFields(['_id']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
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

