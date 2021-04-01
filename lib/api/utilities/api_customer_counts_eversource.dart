library api.utilities.api_customer_counts_eversource;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiCustomerCounts {
  DbCollection coll1;

  ApiCustomerCounts(Db db) {
    coll1 = db.collection('eversource_customer_counts');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/customercounts/eversource/zones', (Request request) async {
      var res = await eversourceZones();
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/customercounts/eversource/zone/<zone>',
        (Request request, String zone) async {
      var res = await eversourceCustomerCounts(zone);
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/customercounts/unique/utility/zone/service/rateclass',
        (Request request) async {
      var res = await uniqueUtilityZoneServiceRateClass();
      return Response.ok(json.encode(res), headers: headers);
    });

    return router;
  }

  /// get available zones
  Future<List<String>> eversourceZones() async {
    var rows = await coll1.distinct('zone');
    var out = (rows['values'] as List).cast<String>();
    return out..sort();
  }

  /// return the historical counts and usage by zone
  Future<List<Map<String, dynamic>>> eversourceCustomerCounts(
      String zone) async {
    var query = where;
    query.eq('zone', zone);
    query = query.excludeFields(['_id']);
    return coll1.find(query).toList();
  }

  /// get unique utilities/zones/service/rateclass combos
  Future<List<Map<String, dynamic>>> uniqueUtilityZoneServiceRateClass() async {
    var pipeline = [];
    pipeline.add({
      '\$group': {
        '_id': {
          'zone': '\$zone',
          'service': '\$service',
          'rateClass': '\$rateClass'
        },
      }
    });
    var res = coll1.aggregateToStream(pipeline);
    var out = <Map<String, dynamic>>[];
    await for (var e in res) {
      out.add({'utility': 'eversource'}..addAll(e['_id']));
    }
    return out;
  }
}
