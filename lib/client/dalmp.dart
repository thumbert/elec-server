import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';

/// A Dart client for pulling DA LMP prices from Mongo supporting several
/// regions.
class DaLmp {
  DaLmp(http.Client client, {this.rootUrl = 'http://localhost:8000'});

  String rootUrl;
  final String servicePath = '/da/v1/';

  final _isoMap = <Iso, String>{
    Iso.newEngland: '/isone',
    Iso.newYork: '/nyiso',
  };

  /// Get hourly prices for a ptid between a start and end date.
  /// Return an hourly timeseries.
  Future<TimeSeries<double>> getHourlyLmp(
      Iso iso, int ptid, LmpComponent component, Date start, Date end) async {
    var cmp = component.toString();
    var url =
        '$rootUrl${_isoMap[iso]!}${servicePath}hourly/$cmp/ptid/${ptid.toString()}/start/${start.toString()}/end/${end.toString()}';

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as Map;
    return TimeSeries.fromIterable(data.entries.expand((e) {
      var date = Date(int.parse(e.key.substring(0, 4)),
          int.parse(e.key.substring(5, 7)), int.parse(e.key.substring(8)),
          location: iso.preferredTimeZoneLocation);
      var hours = date.hours();
      var out = <IntervalTuple<double>>[];
      for (var i = 0; i < hours.length; ++i) {
        out.add(IntervalTuple(hours[i], (e.value[i] as num).toDouble()));
      }
      return out;
    }));
  }

  /// Get daily prices for a ptid/bucket between a start and end date.
  Future<TimeSeries<double>> getDailyLmpBucket(Iso iso, int ptid,
      LmpComponent component, Bucket bucket, Date start, Date end) async {
    var cmp = component.toString();
    var url =
        '$rootUrl${_isoMap[iso]!}${servicePath}daily/$cmp/ptid/${ptid.toString()}/start/${start.toString()}/end/${end.toString()}/bucket/${bucket.name}';

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    var ts = TimeSeries.fromIterable(data.map((e) => IntervalTuple<double>(
        Date.parse(e['date'], location: iso.preferredTimeZoneLocation),
        e[cmp])));
    return ts;
  }

  /// get the daily prices for all nodes in the db as calculated by mongo
  Future<Map<int, TimeSeries<num>>> getDailyPricesAllNodes(
      Iso iso, LmpComponent component, Date start, Date end) async {
    var cmp = component.toString();
    var url =
        '$rootUrl${_isoMap[iso]!}${servicePath}daily/mean/$cmp/start/${start.toString()}/end/${end.toString()}';

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    var grp = groupBy(data, (e) => (e as Map)['ptid'] as int);

    var out = <int, TimeSeries<num>>{};
    for (var ptid in grp.keys) {
      out[ptid] = TimeSeries.fromIterable(grp[ptid]!.map((e) =>
          IntervalTuple<double>(
              Date.parse(e['date'], location: iso.preferredTimeZoneLocation),
              e[cmp])));
    }
    return out;
  }

  /// Get monthly prices for a ptid/bucket between a start and end date.
  Future<TimeSeries<double>> getMonthlyLmpBucket(Iso iso, int ptid,
      LmpComponent component, Bucket bucket, Month start, Month end) async {
    var cmp = component.toString();
    var url =
        '$rootUrl${_isoMap[iso]!}${servicePath}monthly/$cmp/ptid/${ptid.toString()}/start/${start.toIso8601String()}/end/${end.toIso8601String()}/bucket/${bucket.name}';

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    var ts = TimeSeries.fromIterable(data.map((e) => IntervalTuple<double>(
        Month.parse(e['month'], location: iso.preferredTimeZoneLocation),
        e[cmp])));
    return ts;
  }
}
