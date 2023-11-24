library client.isone.isone_btm_solar;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:http/http.dart';
import 'package:timeseries/timeseries.dart';


class IsoneBtmSolar {

  IsoneBtmSolar({required this.rootUrl});

  final String rootUrl;

  Future<TimeSeries<num>> getHourlyBtmForZone(Term term, {required LoadZone zone}) async {
    var zoneName = zone.name;
    if (zoneName == 'MAINE') zoneName = 'ME';
    var url = '$rootUrl/isone/btm/solar/v1/zone/$zoneName'
        '/start/${term.startDate}/end/${term.endDate}';
    var res = await get(Uri.parse(url));
    var data = json.decode(res.body) as List;
    return _format(data);
  }

  Future<TimeSeries<num>> getHourlyBtmForPool(Term term) async {
    var url = '$rootUrl/isone/btm/solar/v1/zone/ISONE'
        '/start/${term.startDate}/end/${term.endDate}';
    var res = await get(Uri.parse(url));
    var data = json.decode(res.body) as List;
    return _format(data);
  }

  TimeSeries<num> _format(List data) {
    var out = TimeSeries<num>();
    for (Map<String,dynamic> e in data) {
      var date = Date.fromIsoString(e['date'], location: IsoNewEngland.location);
      var mwh = e['values'] as List;
      var hours = date.hours();
      for (var i=0; i<hours.length; i++) {
        out.add(IntervalTuple<num>(hours[i], mwh[i]));
      }
    }
    return out;
  }
}