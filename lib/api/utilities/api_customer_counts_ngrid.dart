import 'dart:async';

import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import '../../src/utils/api_response.dart';


// @ApiClass(name: 'ngrid/', version: 'v1')
class ApiCustomerCounts {
  late DbCollection coll;
  String collectionName = 'ngrid_customer_counts';

  ApiCustomerCounts(Db db) {
    coll = db.collection(collectionName);
  }

  /// return the historical usage of this town
  // @ApiMethod(path: 'customercounts/kwh/town/{town}')
  Future<ApiResponse> apiKwhTown(String town) async {
    var query = where;
    query = query.eq('town', town);
    query = query.eq('variable', 'kWh');
    query = query.excludeFields(['_id']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  /// return the historical usage for each of the towns in this zone
  // @ApiMethod(path: 'customercounts/kwh/zone/{zone}/rateclass/{rateclass}')
  Future<ApiResponse> apiKwhZoneRateClass(String zone, String rateclass) async {
    var query = where;
    query = query.eq('zone', zone.toUpperCase());
    query = query.eq('rateClass', rateclass);
    query = query.eq('variable', 'kWh');
    query = query.excludeFields(['_id']);
    var res = await coll.find(query).toList();
    return ApiResponse()..result = json.encode(res);
  }

  /// return the available zones
  // @ApiMethod(path: 'customercounts/zones')
  Future<List<String>> getAvailableZones() async {
    Map data = await coll.distinct('zone');
    List<String> days = data['values'];
    days.sort((a, b) => a.compareTo(b));
    return days;
  }

  /// return the available towns
  // @ApiMethod(path: 'customercounts/towns')
  Future<List<String>> getAvailableTowns() async {
    Map data = await coll.distinct('town');
    List<String> days = data['values'];
    days.sort((a, b) => a.compareTo(b));
    return days;
  }

  /// return the unique rate classes
  // @ApiMethod(path: 'customercounts/rateclasses')
  Future<List<String>> getAvailableRateClasses() async {
    Map data = await coll.distinct('rateClass');
    List<String> days = data['values'];
    days.sort((a, b) => a.compareTo(b));
    return days;
  }

}


