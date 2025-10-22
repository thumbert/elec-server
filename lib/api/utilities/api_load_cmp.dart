import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiLoadCmp {
  ApiLoadCmp(Db db) {
    coll = db.collection('load_cmp');
  }
  late final DbCollection coll;

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/customerClasses', (Request request) async {
      var aux = await coll.distinct('class');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get('/settlements', (Request request) async {
      var aux = await coll.distinct('settlement');
      var res = <String>[...aux['values']];
      res.sort();
      return Response.ok(json.encode(res), headers: headers);
    });

    router.get(
        '/class/<customerClass>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String customerClass, String start, String end,
            String settlement) async {
      var aux = await getLoad(customerClass, start, end, settlement);
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  Future<List<Map<String, dynamic>>> getLoad(
      String customerClass, String start, String end, String settlement) async {
    var query = where
      ..eq('settlement', settlement.toLowerCase())
      ..eq('class', customerClass)
      ..gte('date', Date.parse(start).toString())
      ..lte('date', Date.parse(end).toString())
      ..excludeFields(['_id', 'class', 'settlement']);
    return coll.find(query).toList();
  }
}
