library client.marks.forward_marks;

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:elec/elec.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/risk_system/marks/monthly_curve.dart';

class ForwardMarks {
  final String rootUrl;
  final String servicePath;
  final location = getLocation('America/New_York');
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');

  ForwardMarks(http.Client client,
      {this.rootUrl = 'http://localhost:8080/',
      this.servicePath = 'forward_marks/v1/'});

  /// Get forward marks for one curve, one bucket.
  Future<MonthlyCurve> getMonthlyForwardCurveForBucket(
      String curveId, Bucket bucket, Date asOfDate,
      {Location tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var _url = rootUrl +
        servicePath +
        'curveId/' +
        commons.Escaper.ecapeVariable('${curveId}') +
        '/bucket/' +
        bucket.toString() +
        '/asOfDate/${asOfDate.toString()}/markType/monthly';

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    var aux = json.decode(data['result']);
    var out = TimeSeries<num>();
    for (var e in aux.entries) {
      out.add(IntervalTuple(
          Month.parse(e.key, location: tzLocation, fmt: _isoFmt), e.value));
    }
    return MonthlyCurve(bucket, out);
  }

  /// Get monthly marks for one curve, for one asOfDate, all buckets.
  Future<TimeSeries<Map<Bucket, num>>> getMonthlyForwardCurve(
      String curveId, Date asOfDate,
      {Location tzLocation}) async {
    tzLocation ??= asOfDate.location;
    var _url = rootUrl +
        servicePath +
        'curveId/' +
        commons.Escaper.ecapeVariable('${curveId.toString()}') +
        '/asOfDate/${asOfDate.toString()}/markType/monthly';
    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    var aux = (json.decode(data['result']) as Map);

    var out = TimeSeries<Map<Bucket, num>>();
    var terms = aux['terms'] as List;
    var bucketData = aux['buckets'] as Map<String, dynamic>;
    var buckets = {for (var e in bucketData.keys) e: Bucket.parse(e)};
    for (var i = 0; i < terms.length; i++) {
      var value = {
        for (var e in bucketData.keys) buckets[e]: bucketData[e][i] as num
      };
      out.add(IntervalTuple(
          Month.parse(terms[i], location: tzLocation, fmt: _isoFmt), value));
    }

    return out;
  }
}
