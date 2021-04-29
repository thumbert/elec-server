// library api.isoexpress.api_zonal_demand;
//
// import 'dart:convert';
// import 'dart:async';
// import 'package:mongo_dart/mongo_dart.dart';
// import 'package:date/date.dart';
// import 'package:shelf/shelf.dart';
// import 'package:shelf_router/shelf_router.dart';
//
// class ApiIsoneZonalDemand {
//   DbCollection coll;
//   String collectionName = 'zonal_demand';
//
//   ApiIsoneZonalDemand(Db db) {
//     coll = db.collection(collectionName);
//   }
//
//   final headers = {
//     'Content-Type': 'application/json',
//   };
//
//   Router get router {
//     final router = Router();
//
//     /// Get all zonal load between start/end date
//     /// http://localhost:8000/zonal_demand/v1/isone/load_zone/ptid/4004/start/20190101/end/20190131
//     router.get('/isone/load_zone/{}/start/<start>/end/<end>',
//             (Request request, String ptid, String start, String end) async {
//           var aux = await apiGetZonalRtLoad(int.parse(ptid), start, end);
//           return Response.ok(json.encode(aux), headers: headers);
//         });
//
//     /// Get all zonal load between start/end date
//     /// http://localhost:8000/rt_load/v1/pool/start/20190101/end/20190131
//     router.get('/isone/load_zone/ptid/<ptid>/start/<start>/end/<end>',
//             (Request request, String start, String end) async {
//           var aux = await apiGetPoolRtLoad(start, end);
//           return Response.ok(json.encode(aux), headers: headers);
//         });
//
//     return router;
//   }
//
//   Future<List<Map<String, dynamic>>> apiGetZonalRtLoad(
//       int ptid, String start, String end) async {
//     var query = where
//         .eq('ptid', ptid)
//         .gte('date', Date.parse(start).toString())
//         .lte('date', Date.parse(end).toString())
//         .excludeFields(['_id']).fields(['date', 'rtLoad']);
//     var data = await coll.find(query).toList();
//     return data;
//   }
//
//   Future<List<Map<String, dynamic>>> apiGetPoolRtLoad(
//       String start, String end) async {
//     var query = where
//         .eq('ptid', 4000)
//         .gte('date', Date.parse(start).toString())
//         .lte('date', Date.parse(end).toString())
//         .excludeFields(['_id']).fields(['date', 'rtLoad']);
//     var data = await coll.find(query).toList();
//     return data;
//   }
// }
