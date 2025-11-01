import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

/// A Dart client for pulling LMP prices from DuckDB supporting several
/// regions.
class Lmp {
  Lmp(http.Client client, {required this.rustServer});

  final String rustServer;

  final _isoMap = <Iso, String>{
    Iso.ieso: '/ieso',
    Iso.newEngland: '/isone',
    Iso.newYork: '/nyiso',
  };

  /// Get hourly prices for a ptid between a start and end date.
  /// Return an hourly timeseries.
  Future<TimeSeries<num>> getHourlyLmp(
      {required Iso iso,
      required int ptid,
      required LmpComponent component,
      required Term term,
      required Market market}) async {
    var cmp = component.toString();
    var url = '$rustServer${_isoMap[iso]!}/prices/$market/hourly/'
        'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
        '?ptids=$ptid&components=$cmp';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;

    return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
        Hour.beginning(TZDateTime.parse(
            iso.preferredTimeZoneLocation, e['hour_beginning'])),
        e['price'])));
  }

  // Future<TimeSeries<num>> getHourlyLmpMany(
  //     {required Iso iso,
  //     required List<int> ptids,
  //     required LmpComponent component,
  //     required Term term,
  //     required Market market}) async {
  //   var cmp = component.toString();
  //   var url = '$rustServer${_isoMap[iso]!}/$market/hourly/'
  //       'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
  //       '?ptids=${ptids.join(',')}/components=$cmp';
  //   var response = await http.get(Uri.parse(url));
  //   var data = json.decode(response.body) as List;

  //   return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
  //       Hour.beginning(TZDateTime.parse(
  //           iso.preferredTimeZoneLocation, e['hour_beginning'])),
  //       e['price'])));
  // }
}
