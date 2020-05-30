library client.marks.forward_marks;

import 'dart:convert';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';


class ForwardMarks {
  String rootUrl;
  String servicePath;
  final location = getLocation('US/Eastern');

  ForwardMarks(http.Client client,
      {this.rootUrl = 'http://localhost:8080/', this.servicePath = 'forward_marks/v1/'});

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
