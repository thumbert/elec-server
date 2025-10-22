import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:http/http.dart';
import 'package:timeseries/timeseries.dart';

enum CmpCustomerClass {
  residentialAndSmallCommercial,
  medium,
  large,
}

class Cmp {
  Cmp({required this.rootUrl});

  final String rootUrl;

  Future<TimeSeries<num>> getHourlyLoad(
      Term term, CmpCustomerClass customerClass,
      {String settlementType = 'final'}) async {
    var url = '$rootUrl/utility/v1/cmp/load/class/${customerClass.name}'
        '/start/${term.startDate}/end/${term.endDate}'
        '/settlement/$settlementType';
    var res = await get(Uri.parse(url));
    var data = json.decode(res.body) as List;

    var out = TimeSeries<num>();
    for (var e in data) {
      var date =
          Date.fromIsoString(e['date'], location: IsoNewEngland.location);
      var mwh = e['mwh'] as List;
      var hours = date.hours();
      for (var i = 0; i < hours.length; i++) {
        out.add(IntervalTuple<num>(hours[i], mwh[i]));
      }
    }

    return out;
  }
}
