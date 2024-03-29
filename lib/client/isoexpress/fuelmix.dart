library client.isone.fuelmix;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

class FuelMix {
  final String rootUrl;
  final String servicePath = '/isone/fuelmix/v1/';
  final Location location = getLocation('America/New_York');

  FuelMix(http.Client client, {this.rootUrl = 'http://10.101.22.19:8080'});

  /// Return something like this
  /// ["Coal", "Hydro", "Landfill Gas", "Natural Gas", "Nuclear", "Oil",
  /// "Other", "Refuse", "Solar", "Wind", "Wood"]
  Future<List<String>> getFuelTypes() async {
    var url = '$rootUrl${servicePath}types';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return data.cast<String>();
  }

  /// Get an hourly timeseries with MW generated by this fuel type.
  /// [fuelType] should be one of the fuel types or
  /// "All" if you want the generation summed for all fuel types.
  Future<TimeSeries<num>> getHourlyMwForFuelType(Term term,
      {required String fuelType}) async {
    var url =
        '$rootUrl${servicePath}hourly/mw/type/$fuelType/start/${term.startDate.toString()}/end/${term.endDate.toString()}';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;

    return TimeSeries.fromIterable(data.expand((e) {
      var hours = Date.fromIsoString(e['date'], location: location).hours();
      var mw = e['mw'] as List;
      return hours
          .mapIndexed((index, hour) => IntervalTuple<num>(hour, mw[index]));
    }));
  }

  /// Get the marginal fuel type
  // Future<TimeSeries<String?>> getMarginalFuelType(Interval interval) async {
  //   var start = Date.fromTZDateTime(interval.start);
  //   var end = Date.fromTZDateTime(interval.end.subtract(_1S));
  //   var _url = 'marginal_fuel/start/${start.toString()}/end/${end.toString()}';
  //
  //   var _response = await http.get(Uri.parse(rootUrl + servicePath + _url));
  //   var data = json.decode(_response.body);
  //   var x = (data as List).cast<Map<String, dynamic>>();
  //
  //   return TimeSeries.fromIterable(x.map((Map e) {
  //     var start = TZDateTime.parse(location, e['timestamp']);
  //     var interval = Interval(start, start.add(_1S));
  //     return IntervalTuple(interval, e['marginalFlag']);
  //   }));
  // }
}
