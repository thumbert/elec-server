library api.isoexpress.isone_regulation_requirement;

import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/timezone.dart';
import '../../src/utils/api_response.dart';

@ApiClass(name: 'regulation_requirement', version: 'v1')
class RegulationRequirement {
  DbCollection coll;
  Location location;
  final collectionName = 'regulation_requirement';

  RegulationRequirement(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
  }

  /// http://localhost:8080/regulation_requirement/v1/values
  /// Get all the historical values
  @ApiMethod(path: 'values')
  Future<ApiResponse> regulationRequirements() async {
    var query = where.excludeFields(['_id']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }
}
