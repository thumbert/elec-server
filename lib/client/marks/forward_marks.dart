library client.marks.forward_marks;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/time/shape/hourly_shape.dart';

class ForwardMarks {
  final String rootUrl;
  final String servicePath;
  final location = getLocation('America/New_York');

  ForwardMarks(http.Client client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/forward_marks/v1/'});

  /// Get marks for one curve, for one asOfDate, all available buckets.
  Future<PriceCurve> getForwardCurve(String curveId, Date asOfDate,
      {Location tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var _url = rootUrl +
        servicePath +
        'curveId/${Uri.encodeComponent(curveId)}' +
        '/asOfDate/${asOfDate.toString()}';
    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as Map<String, dynamic>;
    return PriceCurve.fromMongoDocument(data, tzLocation);
  }

  /// Get the volatility surface.
  Future<VolatilitySurface> getVolatilitySurface(String curveId, Date asOfDate,
      {Location tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var _url = rootUrl +
        servicePath +
        'curveId/${Uri.encodeComponent(curveId)}' +
        '/asOfDate/${asOfDate.toString()}';
    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as Map<String, dynamic>;
    return VolatilitySurface.fromJson(data, location: tzLocation);
  }

  /// Get hourly shape curve
  Future<HourlyShape> getHourlyShape(String curveId, Date asOfDate,
      {Location tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var _url = rootUrl +
        servicePath +
        'curveId/${Uri.encodeComponent(curveId)}' +
        '/asOfDate/${asOfDate.toString()}';
    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as Map<String, dynamic>;
    return HourlyShape.fromJson(data, tzLocation);
  }
}
