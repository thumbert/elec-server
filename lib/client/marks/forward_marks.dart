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
  final location = getLocation('US/Eastern');
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');


  ForwardMarks(http.Client client,
      {this.rootUrl = 'http://localhost:8080/', this.servicePath = 'forward_marks/v1/'});

  /// Get forward marks for one curve, one bucket.
  Future<MonthlyCurve> getForwardCurveForBucket(String curveId,
      Bucket bucket, Date asOfDate, {Location tzLocation}) async {

    var _url = rootUrl + servicePath +
        'curveId/' +
        commons.Escaper.ecapeVariable('${curveId}') +
        '/bucket/' + bucket.toString() +
        '/asOfDate/${asOfDate.toString()}';

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    var aux = json.decode(data['result']);
    var out = TimeSeries<num>();
    for (var e in aux.entries) {
      out.add(IntervalTuple(Month.parse(e.key, location: tzLocation, fmt: _isoFmt), e.value));
    }
    return MonthlyCurve(bucket, out);
  }



  /// Get marks for one curve, one asOfDate, all buckets.
  Future<List<Map<String,dynamic>>> getForwardCurve(String curveId, Date asOfDate) async {
    var _url = rootUrl + servicePath + 'asOfDate/${asOfDate.toString()}' +
        '/curveId/' +
        commons.Escaper.ecapeVariable('${curveId.toString()}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
  }


}
