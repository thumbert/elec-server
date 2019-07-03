library api.utilities.api_load_eversource;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/api_response.dart';
import 'package:timezone/timezone.dart';


@ApiClass(name: 'eversource_load', version: 'v1')
class ApiLoadEversource {
  DbCollection coll1;
  var location;

  ApiLoadEversource(Db db) {
    coll1 = db.collection('load_ct');
    location = getLocation('US/Eastern');
  }

  /// return the hourly historical load for ct by load class, including competitive
  /// supply.
  @ApiMethod(path: 'zone/ct/start/{start}/end/{end}')
  Future<ApiResponse> ctLoad(String start, String end) async {
    var query = where;
    query = query.gte('date', Date.parse(start).toString());
    query = query.lte('date', Date.parse(end).toString());
    query = query.excludeFields(['_id']);
    var res = await coll1.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }


}



