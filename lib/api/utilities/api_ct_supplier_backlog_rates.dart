library api.utilities.api_competitive_suppliers_eversource;

import 'dart:convert';
import 'package:elec_server/client/utilities/ct_supplier_backlog_rates.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/timezone.dart';


class ApiCtSupplierBacklogRates {
  ApiCtSupplierBacklogRates(Db db) {
    coll = db.collection('ct_backlog_rates');
  }

  late final DbCollection coll;

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    /// Get data for one utility, all suppliers, all customer classes, between 
    /// a start and end month.
    router.get('/utility/<utility>/start/<start>/end/<end>',
            (Request request, String utility, String start, String end) async {
          var aux = await getAllDataForOneUtility(Utility.parse(utility),
              Month.parse(start, location: UTC), Month.parse(end, location: UTC));
          return Response.ok(json.encode(aux), headers: headers);
        });

    return router;
  }

  /// Return data for one utility.
  Future<List<Map<String, dynamic>>> getAllDataForOneUtility(
      Utility utility, Month startMonth, Month endMonth) async {
    var query = where
      ..eq('utility', utility.toString())
      ..lte('month', endMonth.toIso8601String())
      ..gte('month', startMonth.toIso8601String())
      ..sortBy('month')
      ..excludeFields(['_id']);
    var xs = await coll.find(query).toList();
    return xs;
  }


}



