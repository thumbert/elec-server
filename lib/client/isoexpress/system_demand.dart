import 'dart:async';
import 'dart:convert';
import 'package:elec/risk_system.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';

class SystemDemand {
  final location = getLocation('America/New_York');
  String rootUrl;
  final String servicePath = 'system_demand/v1/';

  SystemDemand(http.Client client, {this.rootUrl = 'http://localhost:8080/'});

  /// Get system demand between a start and end date.
  Future<TimeSeries<double>> getSystemDemand(
      Market market, Date start, Date end) async {
    var url =
        '$rootUrl${servicePath}market/${market.toString()}/start/${start.toString()}/end/${end.toString()}';

    late String columnName;
    if (market.toString().toUpperCase() == 'DA') {
      columnName = 'Day-Ahead Cleared Demand';
    } else if (market.toString().toUpperCase() == 'RT') {
      columnName = 'Total Load';
    }

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    var ts = TimeSeries.fromIterable(data.map((e) => IntervalTuple<double>(
        Hour.beginning(TZDateTime.parse(location, e['hourBeginning'])),
        e[columnName])));
    return ts;
  }
}
