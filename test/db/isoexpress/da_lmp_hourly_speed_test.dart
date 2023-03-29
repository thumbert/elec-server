library test.db.isoexpress.da_lmp_hourly_speed_test;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:elec_server/client/other/ptids.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:http/http.dart' as http;

import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/api/isoexpress/api_isone_dalmp.dart';
import 'package:elec_server/client/dalmp.dart' as client;
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:dama/basic/count.dart';

Future<void> oneByOneAsTimeseries(List<int> ptids,
    {String rootUrl = 'http://127.0.0.1:8080'}) async {
  var futs = [];
  var start = Date.utc(2019, 1, 1);
  var end = Date.utc(2019, 12, 31);
  var daLmp =
      client.DaLmp(http.Client(), rootUrl: rootUrl);
  var sw = Stopwatch()..start();
  var out = <int, TimeSeries<double>>{};
  for (var ptid in ptids) {
    out[ptid] = await daLmp.getHourlyLmp(Iso.newEngland, ptid, LmpComponent.lmp, start, end);
  }
  sw.stop();
  print(sw.elapsedMilliseconds);
}

Future<void> parallelGet(List<int> ptids,
    {String rootUrl = 'http://127.0.0.1:8080'}) async {
  var start = Date.utc(2019, 1, 1);
  var end = Date.utc(2019, 12, 31);
  var daLmp = client.DaLmp(http.Client(), rootUrl: rootUrl);
  var sw = Stopwatch()..start();
  var out = <int, TimeSeries<double>>{};
  var futs = ptids.map(
      (ptid) => daLmp.getHourlyLmp(Iso.newEngland, ptid, LmpComponent.congestion, start, end));
  var res = await Future.wait(futs);
  for (var i = 0; i < ptids.length; i++) {
    out[ptids[i]] = res[i];
  }
  sw.stop();
  print(sw.elapsedMilliseconds);

  /// Can we benefit from run length encoding?  What are the most common prices?
  /// Yes, we can
  // var counts = <double, int>{};
  // for (var ptid in ptids) {
  //   counts = count(out[ptid]!.values, input: counts);
  // }
  // var total = counts.values.fold(0, (int a, b) => a + b);
  //
  // var xs = [
  //   for (var count in counts.entries)
  //     {'congestionValue': count.key, 'freq': count.value / total}
  // ];
  // xs.sort((a, b) => -a['freq']!.compareTo(b['freq']!));
  // xs.take(25).forEach(print);
}

Future<void> compactGet(List<int> ptids,
    {String rootUrl = 'http://127.0.0.1:8080'}) async {
  var sw = Stopwatch()..start();
  var url = Uri.parse(
      '$rootUrl/da_congestion_compact/v1/start/2019-01-01/end/2019-01-31');
  var aux = await http.get(url);
  var data = json.decode(aux.body);
  sw.stop();
  print(sw.elapsedMilliseconds);
  var traces = <Map<String, dynamic>>[];
}

Future<void> speedTest(String rootUrl) async {
  var location = getLocation('America/New_York');
  var daLmp =
      client.DaLmp(http.Client(), rootUrl: rootUrl);

  // get all the list of all ptids
  var ptidApi = PtidsApi(http.Client(), rootUrl: rootUrl);
  var _data = await ptidApi.getPtidTable();
  var ptids = _data.map((e) => e['ptid'] as int).toList();
  print('ptid count: ${ptids.length}');

  // await oneByOneAsTimeseries(ptids);
  // await parallelGet(ptids);
  await compactGet(ptids);
}

void main() async {
  initializeTimeZones();
  DbProd();

  //await speedTest('http://127.0.0.1:8080');
}
