library client.isoexpress.regulation_requirement;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';

class RegulationRequirement {
  String rootUrl;
  String servicePath;
  final location = getLocation('America/New_York');

  List<Map<String, dynamic>> cache;
  num Function(Hour) fCapacity;
  num Function(Hour) fService;

  RegulationRequirement(http.Client client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/regulation_requirement/v1/'});

  Future<TimeSeries<num>> hourlyCapacityRequirement(Interval interval) async {
    cache ??= await getSpecification();
    var hours = interval.splitLeft((dt) => Hour.beginning(dt));
    var out = TimeSeries<num>();
    for (var hour in hours) {
      var value = fCapacity(hour);
      if (value != null) out.add(IntervalTuple(hour, value));
    }
    return out;
  }

  Future<TimeSeries<num>> hourlyServiceRequirement(Interval interval) async {
    cache ??= await getSpecification();
    var hours = interval.splitLeft((dt) => Hour.beginning(dt)).cast<Hour>();
    var out = TimeSeries<num>();
    for (var hour in hours) {
      var value = fService(hour);
      if (value != null) out.add(IntervalTuple(hour, value));
    }
    return out;
  }

  /// Get all the specifications.  Return them sorted by 'from' date.
  Future<List<Map<String, dynamic>>> getSpecification() async {
    var _url = rootUrl + servicePath + 'values';
    var _response = await http.get(Uri.parse(_url));
    var out =
        (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
    out.sort((a, b) => a['from'].compareTo(b['from']));

    /// Add an interval for convenience
    out.forEach((x) {
      var start = Date.parse(x['from'], location: location);
      var end = Date.parse(x['to'], location: location);
      x['interval'] = Interval(start.start, end.end);
    });
    cache = out;
    _makeFunctions(out);
    return out;
  }

  void _makeFunctions(List<Map<String, dynamic>> specification) {
    fCapacity = (Hour hour) {
      if (hour.start
          .isBefore((specification.first['interval'] as Interval).start)) {
        return null;
      }
      for (var x in specification) {
        var interval = x['interval'] as Interval;
        if (interval.containsInterval(hour)) {
          var month = hour.start.month;
          var hourBeginning = hour.start.hour;
          var weekday = hour.start.weekday;
          var capacity = (x['regulation capacity'] as List);
          var one = capacity
              .where((e) =>
                  e['month'] == month && e['hourBeginning'] == hourBeginning)
              .where((e) {
            if (e['weekday'] is List) {
              return (e['weekday'] as List).contains(weekday);
            } else {
              return e['weekday'] == weekday;
            }
          }).first;
          return one['value'] as num;
        }
      }
      return null;
    };
    fService = (Hour hour) {
      if (hour.start
          .isBefore((specification.first['interval'] as Interval).start)) {
        return null;
      }
      for (var x in specification) {
        var interval = x['interval'] as Interval;
        if (interval.containsInterval(hour)) {
          var month = hour.start.month;
          var hourBeginning = hour.start.hour;
          var weekday = hour.start.weekday;
          var capacity = (x['regulation service'] as List);
          var one = capacity
              .where((e) =>
                  e['month'] == month && e['hourBeginning'] == hourBeginning)
              .where((e) {
            if (e['weekday'] is List) {
              return (e['weekday'] as List).contains(weekday);
            } else {
              return e['weekday'] == weekday;
            }
          }).first;
          return one['value'] as num;
        }
      }
      return null;
    };
  }
}
