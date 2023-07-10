library client.marks.forward_marks;

import 'dart:convert';
import 'package:elec/elec.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/time/shape/hourly_shape.dart';

class ForwardMarks {
  ForwardMarks(http.Client client, {this.rootUrl = 'http://localhost:8000'});

  final String rootUrl;
  final String servicePath = '/forward_marks/v1/';

  /// Get marks for one curve, for one asOfDate, all available buckets.
  /// If there is no curve in the database, return an empty [PriceCurve].
  Future<PriceCurve> getForwardCurve(String curveId, Date asOfDate,
      {Location? tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var url =
        '$rootUrl${servicePath}curveId/${Uri.encodeComponent(curveId)}/asOfDate/${asOfDate.toString()}';
    var response = await http.get(Uri.parse(url));
    if (response.body == 'Internal Server Error') {
      return PriceCurve();
    }
    var data = json.decode(response.body) as Map<String, dynamic>;
    return PriceCurve.fromMongoDocument(data, tzLocation);
  }

  /// Get the strip price
  Future<TimeSeries<num>> getStripPrice(
      String curveId, Term term, Bucket bucket, Date start, Date end) async {
    final tzLocation = term.startDate.location;
    var url =
        '$rootUrl${servicePath}curveId/${Uri.encodeComponent(curveId)}/term/${term.toString()}/bucket/${bucket.toString()}/start/${start.toString()}/end/${end.toString()}';
    var response = await http.get(Uri.parse(url));
    if (response.body == 'Internal Server Error') {
      return TimeSeries<num>();
    }
    var data = json.decode(response.body) as Map<String, dynamic>;
    return TimeSeries.fromIterable(data.entries.map((entry) => IntervalTuple(
        Date.parse(entry.key, location: tzLocation), entry.value as num)));
  }

  /// Get the volatility surface.
  Future<VolatilitySurface> getVolatilitySurface(String curveId, Date asOfDate,
      {Location? tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var url =
        '$rootUrl${servicePath}curveId/${Uri.encodeComponent(curveId)}/asOfDate/${asOfDate.toString()}';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as Map<String, dynamic>;
    return VolatilitySurface.fromJson(data, location: tzLocation);
  }

  /// Get hourly shape curve
  Future<HourlyShape> getHourlyShape(String curveId, Date asOfDate,
      {Location? tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var url =
        '$rootUrl${servicePath}curveId/${Uri.encodeComponent(curveId)}/asOfDate/${asOfDate.toString()}';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as Map<String, dynamic>;
    return HourlyShape.fromJson(data, tzLocation);
  }
}
