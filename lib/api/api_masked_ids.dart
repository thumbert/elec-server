library api.isone.api_isone_masked_ids;

import 'dart:async';
import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiMaskedIds {
  late DbCollection coll;
  String collectionName = 'masked_ids';

  ApiMaskedIds(Db db) {
    coll = db.collection(collectionName);
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/all', (Request request) async {
      var res = await allMaskedIds();
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/types', (Request request) async {
      var res = await getTypes();
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/type/<type>', (Request request, String type) async {
      var res = await maskedIdsForType(type);
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/masked_participant_id/<maskedParticipantId>',
        (Request request, String maskedParticipantId) async {
      var res = await getMaskedParticipantId(int.parse(maskedParticipantId));
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/masked_location_id/<maskedLocationId>',
        (Request request, String maskedLocationId) async {
      var res = await getMaskedLocationId(int.parse(maskedLocationId));
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/masked_asset_id/<maskedAssetId>',
        (Request request, String maskedAssetId) async {
      var res = await getMaskedAssetId(int.parse(maskedAssetId));
      return Response.ok(json.encode(res), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> allMaskedIds() async {
    var query = where..excludeFields(['_id']);
    return coll.find(query).toList();
  }

  Future<List<String>> getTypes() async {
    var aux = await coll.distinct('type');
    return (aux['values'] as List).cast<String>();
  }

  Future<List<Map<String, dynamic>>> maskedIdsForType(String type) async {
    var query = where
      ..eq('type', type.toLowerCase())
      ..excludeFields(['_id', 'type']);
    return coll.find(query).toList();
  }

  Future<Map<String, dynamic>> getMaskedParticipantId(
      int maskedParticipantId) async {
    var query = where
      ..eq('type', 'participant')
      ..eq('Masked Participant ID', maskedParticipantId)
      ..excludeFields(['_id', 'type']);
    var aux = await coll.find(query).toList();
    return aux.first;
  }

  Future<Map<String, dynamic>> getMaskedLocationId(int maskedLocationId) async {
    var query = where
      ..eq('type', 'location')
      ..eq('Masked Location ID', maskedLocationId)
      ..excludeFields(['_id', 'type']);
    var aux = await coll.find(query).toList();
    return aux.first;
  }

  Future<Map<String, dynamic>> getMaskedAssetId(int maskedAssetId) async {
    var query = where
      ..eq('type', 'generator')
      ..eq('Masked Asset ID', maskedAssetId)
      ..excludeFields(['_id', 'type']);
    var aux = await coll.find(query).toList();
    return aux.first;
  }
}
