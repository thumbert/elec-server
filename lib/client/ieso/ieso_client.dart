library client.ieso.rt_zonal_demand;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:http/http.dart' as http;

enum IesoFuelType {
  biofuel,
  gas,
  hydro,
  nuclear,
  solar,
  wind,
}

class IesoClient {
  IesoClient(this.client, {required this.rootUrl});

  final http.Client client;
  final String rootUrl;

  /// Get hourly rt zonal demand.
  /// [term] should be in 'America/Cancun'.
  Future<TimeSeries<num>> hourlyRtZonalDemand(
      IesoLoadZone loadZone, Term term) async {
    if (term.location.name != 'EST') {
      throw ArgumentError('Term needs to be in EST timezone.  Use Ieso.location');
    }
    var url = '$rootUrl/ieso/rt/zonal_demand/v1/zone/${loadZone.toString()}'
        '/start/${term.startDate.toString()}/end/${term.endDate.toString()}';
    var aux = await http.get(Uri.parse(url));
    var data = json.decode(aux.body) as List;
    data.sort((a, b) => a['date'].compareTo(b['date']));

    var out = TimeSeries<num>();
    for (var e in data) {
      var hours =
          Date.fromIsoString(e['date'], location: Ieso.location).hours();
      for (var i = 0; i < hours.length; i++) {
        out.add(IntervalTuple(hours[i], e['values'][i]));
      }
    }
    return out;
  }

  /// Get hourly rt generation for one generator.  Generator name should be
  /// capitalized, e.g. 'BRUCEA-G1'.
  /// [term] should be in 'EST' zone.
  /// [variable] can be one of 'output', 'forecast', 'capability', 'capacity'.
  Future<TimeSeries<num>> hourlyRtGeneration(String generatorName, Term term,
      {String variable = 'output'}) async {
    if (term.location.name != 'EST') {
      throw ArgumentError('Term needs to be in EST timezone. Use Ieso.location');
    }
    var url = '$rootUrl/ieso/rt/generation/v1/name/$generatorName/$variable'
        '/start/${term.startDate.toString()}/end/${term.endDate.toString()}';
    var aux = await http.get(Uri.parse(url));
    var data = json.decode(aux.body) as List;
    data.sort((a, b) => a['date'].compareTo(b['date']));

    var out = TimeSeries<num>();
    for (var e in data) {
      var hours =
          Date.fromIsoString(e['date'], location: Ieso.location).hours();
      for (var i = 0; i < hours.length; i++) {
        out.add(IntervalTuple(hours[i], e[variable][i]));
      }
    }
    return out;
  }

  /// Get all variables associated with this generator name.
  Future<Map<String,TimeSeries<num>>> hourlyRtGenerationAll(String generatorName, Term term) async {
    if (term.location.name != 'EST') {
      throw ArgumentError('Term needs to be in EST timezone. Use Ieso.location');
    }
    var url = '$rootUrl/ieso/rt/generation/v1/name/$generatorName'
        '/start/${term.startDate.toString()}/end/${term.endDate.toString()}';
    var aux = await http.get(Uri.parse(url));
    var data = json.decode(aux.body) as List;
    data.sort((a, b) => a['date'].compareTo(b['date']));

    var out = <String,TimeSeries<num>>{
      'output': TimeSeries<num>(),
      'forecast': TimeSeries<num>(),
      'capability': TimeSeries<num>(),
      'capacity': TimeSeries<num>(),
    };
    for (Map e in data) {
      var hours = Date.fromIsoString(e['date'], location: Ieso.location).hours();
      var variables = e.keys.toList()..removeAt(0);
      for (var i = 0; i < hours.length; i++) {
        for (var variable in variables) {
          out[variable]!.add(IntervalTuple(hours[i], e[variable][i]));
        }
      }
    }
    return out..removeWhere((key, value) => value.isEmpty);
  }



  /// Get hourly rt generation for a fuel type, e.g. biofuel, hydro, gas,
  /// nuclear, solar, wind.
  /// [term] should be in 'America/Cancun'.
  /// [variable] can be one of 'output', 'forecast', 'capability', 'capacity'.
  Future<TimeSeries<num>> hourlyRtGenerationForType(
      IesoFuelType fuel, Term term,
      {String variable = 'output'}) async {
    if (term.location.name != 'EST') {
      throw ArgumentError('Term needs to be in EST timezone.  Use Ieso.location');
    }
    var url = '$rootUrl/ieso/rt/generation/v1/fuel/$fuel/$variable'
        '/start/${term.startDate.toString()}/end/${term.endDate.toString()}';
    var aux = await http.get(Uri.parse(url));
    var data = json.decode(aux.body) as List;
    data.sort((a, b) => a['date'].compareTo(b['date']));

    var out = TimeSeries<num>();
    for (var e in data) {
      var hours =
          Date.fromIsoString(e['date'], location: Ieso.location).hours();
      for (var i = 0; i < hours.length; i++) {
        out.add(IntervalTuple(hours[i], e['values'][i]));
      }
    }
    return out;
  }

  /// A sorted list
  Future<List<String>> getAllGeneratorNames() async {
    var url = '$rootUrl/ieso/rt/generation/v1/names';
    var aux = await http.get(Uri.parse(url));
    var data = json.decode(aux.body) as List;
    return data.cast<String>();
  }

}
