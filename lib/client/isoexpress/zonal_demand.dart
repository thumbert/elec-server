library elec_server.client.isoexpress.zonal_demand;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:elec/risk_system.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';

class IsoneZonalDemand {
  final location = getLocation('America/New_York');
  String rootUrl;
  final String servicePath = '/isone/zonal_demand/v1/';

  IsoneZonalDemand(http.Client client, {this.rootUrl = 'http://localhost:8080'});

  static const _ptidMap = <int,String>{
    4001: 'me',
    4002: 'nh',
    4003: 'vt',
    4004: 'ct',
    4005: 'ri',
    4006: 'sema',
    4007: 'wcma',
    4008: 'nema',
  };

  Future<TimeSeries<num>> getPoolDemand(
      Market market, Date start, Date end) async {
    var url = '$rootUrl${servicePath}market/${market.name}/zone/isone/start/${start.toString()}/end/${end.toString()}';
    return _process(Uri.parse(url));
  }


  Future<TimeSeries<num>> getZonalDemand(
      int ptid, Market market, Date start, Date end) async {
    if (!_ptidMap.containsKey(ptid)) {
      throw ArgumentError('Wrong ptid $ptid.  Needs to be one of: ${_ptidMap.keys.join(', ')}');
    }
    var zone = _ptidMap[ptid]!;
    var url = '$rootUrl${servicePath}market/${market.name}/zone/$zone/start/${start.toString()}/end/${end.toString()}';
    return _process(Uri.parse(url));
  }


  Future<TimeSeries<num>> _process(Uri url) async {
    var response = await http.get(url);
    var data = json.decode(response.body) as Map;
    var ts = TimeSeries<num>.fromIterable(data.entries.expand((e) {
      var hours = Date.fromIsoString(e.key, location: location).hours();
      var ys = e.value as List;
      return hours.mapIndexed((index, hour) => IntervalTuple(hour, ys[index]));
    }));

    return ts;
  }

}
