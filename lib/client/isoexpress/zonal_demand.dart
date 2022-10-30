library elec_server.client.isoexpress.zonal_demand;

import 'dart:async';
import 'dart:convert';
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
    var url = '$rootUrl${servicePath}zone/isone/start/${start.toString()}/end/${end.toString()}';
    return _process(Uri.parse(url), market);
  }


  Future<TimeSeries<num>> getZonalDemand(
      int ptid, Market market, Date start, Date end) async {
    if (!_ptidMap.containsKey(ptid)) {
      throw ArgumentError('Wrong ptid $ptid.  Needs to be one of: ${_ptidMap.keys.join(', ')}');
    }
    var zone = _ptidMap[ptid]!;
    var url = '$rootUrl${servicePath}zone/$zone/start/${start.toString()}/end/${end.toString()}';

    return _process(Uri.parse(url), market);
  }


  Future<TimeSeries<num>> _process(Uri url, Market market) async {
    late String columnName;
    if (market == Market.da) {
      columnName = 'DA_Demand';
    } else if (market == Market.rt) {
      columnName = 'RT_Demand';
    } else {
      throw StateError('Unsupported market $market');
    }

    var response = await http.get(url);
    var data = json.decode(response.body) as List;
    var ts = TimeSeries<double>.fromIterable(data.map((e) => IntervalTuple(
        Hour.beginning(TZDateTime.parse(location, e['hourBeginning'])),
        e[columnName])));
    return ts;
  }

}
