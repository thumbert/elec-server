import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';

class EversourceLoad {
  final location = getLocation('America/New_York');
  String rootUrl;
  final String servicePath = 'eversource_load/v1/';

  EversourceLoad(http.Client client, {this.rootUrl = 'http://localhost:8080/'});

  /// Get hourly prices for a ptid between a start and end date.
  Future<TimeSeries<Map<String, num>>> getCtLoad(Date start, Date end) async {
    var _url =
        '$rootUrl${servicePath}zone/ct/start/${start.toString()}/end/${end.toString()}';

    var _response = await http.get(Uri.parse(_url));
    var xs = json.decode(_response.body) as List;

    var ts = TimeSeries<Map<String, num>>.fromIterable([]);
    for (var x in xs) {
      // for all days loop over the hours
      var hours = (x['hourBeginning'] as List).cast<String>();
      for (var i = 0; i < hours.length; i++) {
        var load = Map.fromEntries((x['load'][i] as Map)
            .entries
            .map((e) => MapEntry(e.key as String, e.value as num)));
        ts.add(IntervalTuple(
            Hour.beginning(TZDateTime.parse(location, hours[i])), load));
      }
    }
    return ts;
  }
}
