import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

@Deprecated('Use the new functionality from lib/client/lmp.dart')
class DaLmp {
  /// A Dart client for pulling DA LMP prices for ISONE and NYISO
  DaLmp(http.Client client, {required this.rootUrl});

  final String rootUrl;

  final _isoMap = <Iso, String>{
    Iso.newEngland: '/isone',
    Iso.newYork: '/nyiso',
  };

  /// Get hourly prices for a ptid between a start and end date.
  /// Return an hourly timeseries.
  Future<TimeSeries<num>> getHourlyLmp(
      Iso iso, int ptid, LmpComponent component, Date start, Date end) async {
    var cmp = component.toString();
    var url =
        '$rootUrl${_isoMap[iso]!}/prices/da/hourly/start/${start.toString()}/end/${end.toString()}'
        '?ptids=${ptid.toString()}&components=$cmp';

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return TimeSeries.fromIterable(data.map((e) {
      var hour = Hour.beginning(
          TZDateTime.parse(iso.preferredTimeZoneLocation, e['hour_beginning']));
      return IntervalTuple<num>(hour, e['price']);
    }));
  }

  /// Get daily prices for a ptid/bucket between a start and end date.
  Future<TimeSeries<num>> getDailyLmpBucket(Iso iso, int ptid,
      LmpComponent component, Bucket bucket, Date start, Date end) async {
    var cmp = component.toString();
    var url =
        '$rootUrl${_isoMap[iso]!}/prices/da/daily/start/${start.toString()}/end/${end.toString()}'
        '?ptids=${ptid.toString()}&buckets=${bucket.name}&components=$cmp';

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    var ts = TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
        Date.parse(e['date'], location: iso.preferredTimeZoneLocation),
        e['value'])));
    return ts;
  }

  /// get the daily prices for all nodes
  Future<Map<int, TimeSeries<num>>> getDailyPricesAllNodes(
      Iso iso, LmpComponent component, Date start, Date end) async {
    var cmp = component.toString();
    var url =
        '$rootUrl${_isoMap[iso]!}/prices/da/daily/start/${start.toString()}/end/${end.toString()}'
        '?components=$cmp';

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    var grp = groupBy(data, (e) => (e as Map)['ptid'] as int);

    var out = <int, TimeSeries<num>>{};
    for (var ptid in grp.keys) {
      out[ptid] = TimeSeries.fromIterable(grp[ptid]!.map((e) =>
          IntervalTuple<num>(
              Date.parse(e['date'], location: iso.preferredTimeZoneLocation),
              e['value'])));
    }
    return out;
  }

  /// Get monthly prices for a ptid/bucket between a start and end date.
  Future<TimeSeries<num>> getMonthlyLmpBucket(Iso iso, int ptid,
      LmpComponent component, Bucket bucket, Month start, Month end) async {
    var cmp = component.toString();
    var url =
        '$rootUrl${_isoMap[iso]!}/prices/da/monthly/start/${start.toString()}/end/${end.toString()}'
        '?ptids=${ptid.toString()}&buckets=${bucket.name}&components=$cmp';

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    var ts = TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
        Month.parse(e['month'], location: iso.preferredTimeZoneLocation),
        e['value'])));
    return ts;
  }
}
