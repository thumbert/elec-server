import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

Future<TimeSeries<num>> getHourlyLmpCaiso(
    {required Market market,
    required String locationName,
    required LmpComponent component,
    required Term term,
    required String rustServer}) async {
  final url = '$rustServer/caiso/prices/${market.name.toLowerCase()}/hourly/'
      'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
      '?node_ids=$locationName&components=${component.shortName()}';
  var response = await http.get(Uri.parse(url));
  var data = json.decode(response.body) as List;
  return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
      Hour.beginning(
          TZDateTime.parse(Caiso.location, e['hour_beginning'])),
      e['price'])));
}

Future<TimeSeries<num>> getHourlyLmpIeso(
    {required Market market,
    required String locationName,
    required LmpComponent component,
    required Term term,
    required String rustServer}) async {
  final url = '$rustServer/ieso/prices/${market.name.toLowerCase()}/hourly/'
      'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
      '?locations=$locationName&components=${component.shortName()}';
  var response = await http.get(Uri.parse(url));
  var data = json.decode(response.body) as List;
  return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
      Hour.beginning(
          TZDateTime.parse(Ieso.location, e['hour_beginning'])),
      e['price'])));
}

Future<TimeSeries<num>> getHourlyLmpIsone(
    {required Market market,
    required int ptid,
    required LmpComponent component,
    required Term term,
    required String rustServer}) async {
  final url = '$rustServer/isone/prices/${market.name.toLowerCase()}/hourly/'
      'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
      '?ptids=$ptid&components=${component.shortName()}';
  var response = await http.get(Uri.parse(url));
  var data = json.decode(response.body) as List;
  return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
      Hour.beginning(
          TZDateTime.parse(IsoNewEngland.location, e['hour_beginning'])),
      e['price'])));
}

Future<TimeSeries<num>> getHourlyLmpNyiso(
    {required Market market,
    required int ptid,
    required LmpComponent component,
    required Term term,
    required String rustServer}) async {
  final url = '$rustServer/nyiso/prices/${market.name.toLowerCase()}/hourly/'
      'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
      '?ptids=$ptid&components=${component.shortName()}';
  var response = await http.get(Uri.parse(url));
  var data = json.decode(response.body) as List;
  return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
      Hour.beginning(
          TZDateTime.parse(NewYorkIso.location, e['hour_beginning'])),
      e['price'])));
}

extension CaisoLmpPriceExtension on Caiso {
  Future<TimeSeries<num>> getHourlyLmp(
      {required Market market,
      required String locationName,
      required LmpComponent component,
      required Term term,
      required String rustServer}) async {
    final url = '$rustServer/caiso/prices/${market.name.toLowerCase()}/hourly/'
        'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
        '?node_ids=$locationName&components=${component.shortName()}';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
        Hour.beginning(
            TZDateTime.parse(preferredTimeZoneLocation, e['hour_beginning'])),
        e['price'])));
  }
}

extension IesoLmpPriceExtension on Ieso {
  Future<TimeSeries<num>> getHourlyLmp(
      {required Market market,
      required String locationName,
      required LmpComponent component,
      required Term term,
      required String rustServer}) async {
    final url = '$rustServer/ieso/prices/${market.name.toLowerCase()}/hourly/'
        'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
        '?locations=$locationName&components=${component.shortName()}';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
        Hour.beginning(
            TZDateTime.parse(preferredTimeZoneLocation, e['hour_beginning'])),
        e['price'])));
  }
}

extension IsoneLmpPriceExtension on IsoNewEngland {
  Future<TimeSeries<num>> getHourlyLmp(
      {required Market market,
      required int ptid,
      required LmpComponent component,
      required Term term,
      required String rustServer}) async {
    final url = '$rustServer/isone/prices/${market.name.toLowerCase()}/hourly/'
        'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
        '?ptids=$ptid&components=${component.shortName()}';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
        Hour.beginning(
            TZDateTime.parse(preferredTimeZoneLocation, e['hour_beginning'])),
        e['price'])));
  }
}

extension NyisoLmpPriceExtension on NewYorkIso {
  Future<TimeSeries<num>> getHourlyLmp(
      {required Market market,
      required int ptid,
      required LmpComponent component,
      required Term term,
      required String rustServer}) async {
    final url = '$rustServer/nyiso/prices/${market.name.toLowerCase()}/hourly/'
        'start/${term.startDate.toString()}/end/${term.endDate.toString()}'
        '?ptids=$ptid&components=${component.shortName()}';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return TimeSeries.fromIterable(data.map((e) => IntervalTuple<num>(
        Hour.beginning(
            TZDateTime.parse(preferredTimeZoneLocation, e['hour_beginning'])),
        e['price'])));
  }
}
