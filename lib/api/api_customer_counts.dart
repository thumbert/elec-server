import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';

@ApiClass(name: 'customercounts', version: 'v1')
class ApiCustomerCounts {
  DbCollection coll;
  String collectionName = 'ngrid_customer_counts';

  ApiCustomerCounts(Db db) {
    coll = db.collection(collectionName);
  }

  /// return the historical usage of this town
  @ApiMethod(path: 'kwh/town/{town}')
  Future<List<Map<String, String>>> apiKwhTown(String town) async {
    SelectorBuilder query = where;
    query = query.eq('town', town);
    query = query.eq('variable', 'kWh');
    query = query.excludeFields(['_id']);
    return await coll.find(query).toList();
  }

  /// return the historical usage for each of the towns in this zone
  @ApiMethod(path: 'kwh/zone/{zone}/rateclass/{rateclass}')
  Future<List<Map<String, String>>> apiKwhZoneRateClass(String zone, String rateclass) async {
    SelectorBuilder query = where;
    query = query.eq('zone', zone.toUpperCase());
    query = query.eq('rateClass', rateclass);
    query = query.eq('variable', 'kWh');
    query = query.excludeFields(['_id']);
    return await coll.find(query).toList();
  }

  /// return the available zones
  @ApiMethod(path: 'zones')
  Future<List<String>> getAvailableZones() async {
    Map data = await coll.distinct('zone');
    List<String> days = data['values'];
    days.sort((a, b) => a.compareTo(b));
    return days;
  }

  /// return the available towns
  @ApiMethod(path: 'towns')
  Future<List<String>> getAvailableTowns() async {
    Map data = await coll.distinct('town');
    List<String> days = data['values'];
    days.sort((a, b) => a.compareTo(b));
    return days;
  }

  /// return the unique rate classes
  @ApiMethod(path: 'rateclasses')
  Future<List<String>> getAvailableRateClasses() async {
    Map data = await coll.distinct('rateClass');
    List<String> days = data['values'];
    days.sort((a, b) => a.compareTo(b));
    return days;
  }

}


