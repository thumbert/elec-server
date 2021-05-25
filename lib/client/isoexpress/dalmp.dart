library elec_server.client.dalmp.v1;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';

class DaLmp {
  String rootUrl;
  String servicePath;
  final location = getLocation('America/New_York');

  DaLmp(http.Client client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/dalmp/v1/'});

  /// Get hourly prices for a ptid between a start and end date.
  Future<TimeSeries<double>> getHourlyLmp(
      int ptid, LmpComponent component, Date start, Date end) async {
    var cmp = component.toString();
    var _url = rootUrl +
        servicePath +
        'hourly/$cmp/ptid/${ptid.toString()}' +
        '/start/${start.toString()}' +
        '/end/${end.toString()}';

    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as List;
    var ts = TimeSeries.fromIterable(data.map((e) => IntervalTuple<double>(
        Hour.beginning(TZDateTime.parse(location, e['hourBeginning'])),
        e[cmp])));
    return ts;
  }

  /// Get daily prices for a ptid/bucket between a start and end date.
  Future<TimeSeries<double>> getDailyLmpBucket(int ptid, LmpComponent component,
      Bucket bucket, Date start, Date end) async {
    var cmp = component.toString();
    var _url = rootUrl +
        servicePath +
        'daily/$cmp/ptid/${ptid.toString()}' +
        '/start/${start.toString()}' +
        '/end/${end.toString()}' +
        '/bucket/${bucket.name}';

    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as List;
    var ts = TimeSeries.fromIterable(data.map((e) => IntervalTuple<double>(
        Date.parse(e['date'], location: location), e[cmp])));
    return ts;
  }

  /// get the daily prices for all nodes in the db as calculated by mongo
  Future<Map<int, TimeSeries<num>>> getDailyPricesAllNodes(
      LmpComponent component, Date start, Date end) async {
    var cmp = component.toString();
    var _url = rootUrl +
        servicePath +
        'daily/mean/$cmp' +
        '/start/${start.toString()}' +
        '/end/${end.toString()}';

    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as List;
    var grp = groupBy(data, (e) => (e as Map)['ptid'] as int);

    var out = <int, TimeSeries<num>>{};
    for (var ptid in grp.keys) {
      out[ptid] = TimeSeries.fromIterable(grp[ptid]!.map((e) =>
          IntervalTuple<double>(
              Date.parse(e['date'], location: location), e[cmp])));
    }
    return out;
  }

  /// Get monthly prices for a ptid/bucket between a start and end date.
  Future<TimeSeries<double>> getMonthlyLmpBucket(int ptid,
      LmpComponent component, Bucket bucket, Month start, Month end) async {
    var cmp = component.toString();
    var _url = rootUrl +
        servicePath +
        'monthly/$cmp/ptid/${ptid.toString()}' +
        '/start/${start.toIso8601String()}' +
        '/end/${end.toIso8601String()}' +
        '/bucket/${bucket.name}';

    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as List;
    var ts = TimeSeries.fromIterable(data.map((e) => IntervalTuple<double>(
        Month.parse(e['month'], location: location), e[cmp])));
    return ts;
  }
}
