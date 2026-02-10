// import 'package:dotenv/dotenv.dart' as dotenv;
// import 'package:elec/elec.dart';
// import 'package:elec_server/client/dalmp.dart' as client;
// import 'package:elec_server/client/lmp.dart';
// import 'package:elec_server/src/db/lib_prod_dbs.dart';
// import 'package:elec_server/src/db/nyiso/rt_lmp_hourly.dart';
// import 'package:http/http.dart' as http;
// import 'package:test/test.dart';
// import 'package:timeseries/timeseries.dart';

// import 'package:timezone/data/latest.dart';
// import 'package:date/date.dart';

// Future<void> tests(String rootUrl) async {
//   group('Nyiso RT LMP client tests: ', () {
//     var daLmp = Lmp(http.Client(), rustServer: rootUrl);
//     test('get daily peak price between two dates', () async {
//       var data = await daLmp.getDailyLmpBucket(61752, LmpComponent.lmp,
//           Bucket.b5x16, Date.utc(2019, 1, 1), Date.utc(2019, 1, 5));
//       expect(data.length, 3);
//       expect(data.toList(), [
//         IntervalTuple(Date(2019, 1, 2, location: location), 31.678124999999998),
//         IntervalTuple(Date(2019, 1, 3, location: location), 29.316875000000003),
//         IntervalTuple(Date(2019, 1, 4, location: location), 23.630625000000002),
//       ]);
//     });
//     test('get monthly peak price between two dates', () async {
//       var data = await daLmp.getMonthlyLmpBucket(61752, LmpComponent.congestion,
//           IsoNewEngland.bucket5x16, Month.utc(2019, 1), Month.utc(2019, 12));
//       expect(data.length, 12);
//       expect(
//           data.first,
//           IntervalTuple(
//               Month(2019, 1, location: location), -7.513068181818175));
//     });
//     test('get hourly price for 2017-01-01', () async {
//       var data = await daLmp.getHourlyLmp(
//           61752, LmpComponent.lmp, Date.utc(2019, 1, 1), Date.utc(2019, 1, 1));
//       expect(data.length, 24);
//       expect(
//           data.first,
//           IntervalTuple(
//               Hour.beginning(TZDateTime(location, 2019, 1, 1)), 11.83));
//     });
//     test('get daily prices all nodes', () async {
//       var data = await daLmp.getDailyPricesAllNodes(
//           LmpComponent.lmp, Date.utc(2019, 1, 1), Date.utc(2019, 1, 3));
//       expect(data.length, 570);
//       var zA = data[61752]!;
//       expect(zA.first.value, 17.090833333333332);
//     });
//   });
// }

// void main() async {
//   initializeTimeZones();
//   dotenv.load('.env/prod.env');
//   await tests(dotenv.env['RUST_SERVER']!);
// }
