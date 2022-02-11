// library elec_server.client.binding_constraints.v1;
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:date/date.dart';
// import 'package:timezone/timezone.dart';
//
// class BindingConstraintsApi {
//   String rootUrl;
//   String servicePath;
//   final location = getLocation('America/New_York');
//
//   BindingConstraintsApi(http.Client client,
//       {this.rootUrl = 'http://localhost:8080', this.servicePath = '/bc/v1/'});
//
//   /// Get all the constraints in a given interval.
//   Future<List<Map<String, dynamic>>> getDaBindingConstraints(
//       Interval interval) async {
//     var start = Date.fromTZDateTime(interval.start);
//     Date end;
//     if (isBeginningOfDay(interval.end)) {
//       end = Date.fromTZDateTime(interval.end.subtract(Duration(seconds: 1)));
//     } else {
//       end = Date.fromTZDateTime(interval.end);
//     }
//     var _url = rootUrl +
//         servicePath +
//         'market/da' +
//         '/start/${start.toString()}' +
//         '/end/${end.toString()}';
//     var _response = await http.get(Uri.parse(_url));
//     return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
//   }
//
//   /// Get all the occurrences of this constraint in the history.
//   Future<List<Map<String, dynamic>>> getDaBindingConstraint(
//       String name, Date start, Date end) async {
//     var _url = rootUrl +
//         servicePath +
//         'market/da' +
//         '/constraintname/' +
//         Uri.encodeComponent(name) +
//         '/start/${start.toString()}' +
//         '/end/${end.toString()}';
//
//     var _response = await http.get(Uri.parse(_url));
//     return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
//   }
//
//   /// Return an indicator Map with keys the constraint names and values
//   /// an hourly time series with value = 1 for the hours where the given
//   /// constraint was binding.
//   // Future<Map<String,TimeSeries<num>>> getBindingConstraintIndicator(
//   //     Date start, Date end) async {
//   //   var aux = await getDaBindingConstraints(start, end);
//   //   var bux = aux.map((e) => <String,dynamic>{
//   //     'Constraint Name': e['Constraint Name'],
//   //     'hour': Hour.beginning(TZDateTime.parse(location, e['hourBeginning'])),
//   //   });
//   //   var grp = groupBy(bux, (dynamic e) => e['Constraint Name'] as String);
//   //
//   //   return grp.map((name, v) {
//   //     var hours = v.map((e) => e['hour'] as Hour).toSet();
//   //     return MapEntry(name, TimeSeries.fill(hours, 1));
//   //   });
//   // }
//
// }
