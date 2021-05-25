library api.isoexpress.isone_regulation_requirement;

import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class RegulationRequirement {
  late DbCollection coll;
  Location? location;
  final collectionName = 'regulation_requirement';

  RegulationRequirement(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get all the historical values
    /// http://localhost:8080/regulation_requirement/v1/values
    router.get('/values', (Request request) async {
      var aux = await regulationRequirements();
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// Get all the historical values
  Future<List<Map<String, dynamic>>> regulationRequirements() async {
    var query = where.excludeFields(['_id']);
    return coll.find(query).toList();
  }
}
