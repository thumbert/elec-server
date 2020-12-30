library client.marks.forward_marks;

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/time/shape/hourly_shape.dart';

class ForwardMarks {
  final String rootUrl;
  final String servicePath;
  final location = getLocation('America/New_York');
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');

  ForwardMarks(http.Client client,
      {this.rootUrl = 'http://localhost:8080/',
      this.servicePath = 'forward_marks/v1/'});

  /// Get marks for one curve, for one asOfDate, all available buckets.
  Future<PriceCurve> getForwardCurve(String curveId, Date asOfDate,
      {Location tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var _url = rootUrl +
        servicePath +
        'curveId/' +
        commons.Escaper.ecapeVariable('${curveId.toString()}') +
        '/asOfDate/${asOfDate.toString()}';
    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    var aux = json.decode(data['result']) as Map<String, dynamic>;
    return PriceCurve.fromMongoDocument(aux, tzLocation);
  }

  /// Get hourly shape curve
  Future<HourlyShape> getHourlyShape(String curveId, Date asOfDate,
      {Location tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var _url = rootUrl +
        servicePath +
        'curveId/' +
        commons.Escaper.ecapeVariable('${curveId.toString()}') +
        '/asOfDate/${asOfDate.toString()}';
    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    var aux = (json.decode(data['result']) as Map<String, dynamic>);
    return HourlyShape.fromJson(aux, tzLocation);
  }
}

// /// Get forward marks for one curve, one bucket.
// Future<MonthlyCurve> getForwardCurveForBucket(
//     String curveId, Bucket bucket, Date asOfDate,
//     {Location tzLocation}) async {
//   tzLocation ??= asOfDate.location;
//   var _url = rootUrl +
//       servicePath +
//       'curveId/' +
//       commons.Escaper.ecapeVariable('${curveId}') +
//       '/bucket/' +
//       bucket.toString() +
//       '/asOfDate/${asOfDate.toString()}';
//
//   var _response = await http.get(_url);
//   var data = json.decode(_response.body);
//   var aux = json.decode(data['result']);
//   var out = TimeSeries<num>();
//   for (var e in aux.entries) {
//     out.add(IntervalTuple(
//         Month.parse(e.key, location: tzLocation, fmt: _isoFmt), e.value));
//   }
//   return MonthlyCurve(bucket, out);
// }
