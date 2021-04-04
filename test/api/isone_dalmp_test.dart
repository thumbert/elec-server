// library test.isone_dalmp_test;
//
// import 'dart:convert';
// import 'package:test/test.dart';
// import 'package:http/http.dart' as http;
// //import 'package:dotenv/dotenv.dart' as dotenv;
// import 'package:mongo_dart/mongo_dart.dart' as mongo;
// import 'package:timezone/data/latest.dart';
// import 'package:date/date.dart';
// import 'package:elec_server/api/isoexpress/api_isone_dalmp.dart';
// import 'package:elec_server/client/isoexpress/dalmp.dart' as client;
// import 'package:timezone/timezone.dart';
// import 'package:timeseries/timeseries.dart';
// import 'package:elec/elec.dart';
// import 'package:elec/risk_system.dart';
//
// void tests() async {
//   mongo.Db db;
//   DaLmp api;
//   setUp(() async {
//     db = mongo.Db('mongodb://localhost/isoexpress');
//     api = DaLmp(db);
//     await db.open();
//   });
//   tearDown(() async {
//     await db.close();
//   });
//   group('API DA Hourly prices:', () {
//     var shelfRootUrl = dotenv.env['SHELF_ROOT_URL'];
//     test('get lmp data for 2 days', () async {
//       var aux = await api.getHourlyData(
//           4000, Date(2017, 1, 1), Date(2017, 1, 2), 'lmp');
//       expect(aux.length, 48);
//       expect(aux.first, {
//         'hourBeginning': '2017-01-01 00:00:00.000-0500',
//         'lmp': 35.12,
//       });
//       var res = await http.get(
//           '$shelfRootUrl/dalmp/v1/hourly/component/lmp/'
//           'ptid/4000/start/2017-01-01/end/2017-01-02',
//           headers: {'Content-Type': 'application/json'});
//       var data = json.decode(res.body) as List;
//       expect(data.length, 48);
//       expect(data.first, {
//         'hourBeginning': '2017-01-01 00:00:00.000-0500',
//         'lmp': 35.12,
//       });
//     });
//     test('get lmp data for 2 days (compact)', () async {
//       var aux = await api.getHourlyPricesCompact(
//           'lmp', 4000, '2017-01-01', '2017-01-02');
//       expect(aux.length, 48);
//       expect(aux.first, 35.12);
//     });
//
//     test('get daily lmp prices by peak bucket', () async {
//       var data = await api.getDailyBucketPrice(
//           'lmp', 4000, '2017-07-01', '2017-07-07', '5x16');
//       expect(data.length, 4);
//       expect(data.first, {'date': '2017-07-03', 'lmp': 35.225});
//     });
//
//     test('get daily lmp prices by flat bucket', () async {
//       var data = await api.getDailyBucketPrice(
//           'lmp', 4000, '2017-07-01', '2017-07-07', 'flat');
//       expect(data[2]['lmp'], 30.2825);
//       expect(data.length, 7);
//     });
//
//     test('get mean daily lmp prices all nodes 2017-01-01 (mongo)', () async {
//       var data = await api.dailyPriceByPtid('lmp', '2017-07-03', '2017-07-03');
//       var hub = data.firstWhere((e) => e['ptid'] == 4000);
//       expect((hub['lmp'] as num).toStringAsFixed(4), '30.2825');
//       expect(data.length, 1142);
//     });
//
//     test('get monthly lmp prices by flat bucket', () async {
//       var data = await api.getMonthlyBucketPrice(
//           'lmp', 4000, '201707', '201708', 'flat');
//       expect(data.length, 2);
//       expect(data.first, {'month': '2017-07', 'lmp': 27.604422043010757});
//     });
//   });
//   group('DAM prices client tests: ', () {
//     var location = getLocation('America/New_York');
//     var shelfRootUrl = dotenv.env['SHELF_ROOT_URL'];
//     var daLmp = client.DaLmp(http.Client(), rootUrl: shelfRootUrl);
//     test('get daily peak price between two dates', () async {
//       var data = await daLmp.getDailyLmpBucket(4000, LmpComponent.lmp,
//           IsoNewEngland.bucket5x16, Date(2017, 1, 1), Date(2017, 1, 5));
//       expect(data.length, 3);
//       expect(data.toList(), [
//         IntervalTuple(Date(2017, 1, 3, location: location), 45.64124999999999),
//         IntervalTuple(Date(2017, 1, 4, location: location), 39.103125),
//         IntervalTuple(Date(2017, 1, 5, location: location), 56.458749999999995)
//       ]);
//     });
//
//     test('get monthly peak price between two dates', () async {
//       var data = await daLmp.getMonthlyLmpBucket(4000, LmpComponent.lmp,
//           IsoNewEngland.bucket5x16, Month(2017, 1), Month(2017, 8));
//       expect(data.length, 8);
//       expect(data.first,
//           IntervalTuple(Month(2017, 1, location: location), 42.55883928571426));
//     });
//
//     test('get hourly price for 2017-01-01', () async {
//       var data = await daLmp.getHourlyLmp(
//           4000, LmpComponent.lmp, Date(2017, 1, 1), Date(2017, 1, 1));
//       expect(data.length, 24);
//       expect(
//           data.first,
//           IntervalTuple(
//               Hour.beginning(TZDateTime(location, 2017, 1, 1)), 35.12));
//     });
//
//     test('get daily prices all nodes', () async {
//       var data = await daLmp.getDailyPricesAllNodes(
//           LmpComponent.lmp, Date(2017, 1, 1), Date(2017, 1, 3));
//       expect(data.length, 1136);
//       var p321 = data[321];
//       expect(p321.first.value, 37.755);
//     });
//   });
// }
//
// void main() async {
//   initializeTimeZones();
//
//   dotenv.load('.env/prod.env');
//
//   tests();
// }
