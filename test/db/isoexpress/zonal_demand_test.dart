library test.db.isoexpress.zonal_demand_test;

import 'dart:convert';

import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/api/isoexpress/api_isone_zonal_demand.dart';
import 'package:elec_server/client/isoexpress/zonal_demand.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';


Future<void> tests(String rootUrl) async {
  // group('ISONE Zonal demand archive tests', (){
  //   var archive = ZonalDemandArchive();
  //   test('read year 2016', () {
  //     var file = archive.getFilename(2016);
  //     var data = archive.processFile(file);
  //     // check DST spring-forward date
  //     var d1 = data.firstWhere((e) => e['date'] == '2016-03-13' && e['zoneName'] == 'ISONE');
  //     expect(d1.keys.toSet(), {'date', 'zoneName', 'DA_Demand', 'RT_Demand'});
  //     expect((d1['RT_Demand'] as List).length, 23);
  //     // check DST fall-back date
  //     var d2 = data.firstWhere((e) => e['date'] == '2016-11-06' && e['zoneName'] == 'ISONE');
  //     expect((d2['RT_Demand'] as List).length, 25);
  //   });
  // });

  group('Api ISONE zonal demand tests:', () {
    var api = ZonalDemand(DbProd.isoexpress);
    setUp(() async => await api.db.open());
    tearDown(() async => await api.db.close());
    test('http get data for isone, 2017-01-01', () async {
      var url = '$rootUrl/isone/zonal_demand/v1/market/rt/zone/isone/start/20170101/end/20170101';
      var res = await get(Uri.parse(url));
      var data = json.decode(res.body) as Map;
      expect(data.length, 1);
      expect(data.keys.toSet(), {
        '2017-01-01',
      });
    });
  });
  group('Client ISONE zonal demand tests:', () {
    var client = IsoneZonalDemand(Client());
    test('get isone rt demand one day', () async {
      var rtDemand = await client.getPoolDemand(Market.rt, Date.utc(2020, 1, 1), Date.utc(2020, 1, 1));
      expect(rtDemand.length, 24);
      expect(rtDemand.first,
          IntervalTuple<num>(Hour.beginning(TZDateTime(IsoNewEngland.location, 2020)), 11441.992));
    });
    test('get isone rt demand across fall DST', () async {
      var rtDemand = await client.getPoolDemand(Market.rt, Date.utc(2016, 11, 6), Date.utc(2016, 11, 7));
      expect(rtDemand.length, 49);
      expect(rtDemand.first,
          IntervalTuple<num>(Hour.beginning(TZDateTime(IsoNewEngland.location, 2016, 11, 6)), 10069.187));
    });
    test('get isone rt demand across spring DST', () async {
      var rtDemand = await client.getPoolDemand(Market.rt, Date.utc(2016, 3, 13), Date.utc(2016, 3, 14));
      expect(rtDemand.length, 47);
      expect(rtDemand.first,
          IntervalTuple<num>(Hour.beginning(TZDateTime(IsoNewEngland.location, 2016, 3, 13)), 9972.615));
    });

    test('get isone ct rt demand', () async {
      var rtDemand = await client.getZonalDemand(4004, Market.rt, Date.utc(2020, 1, 1), Date.utc(2020, 1, 1));
      expect(rtDemand.length, 24);
      expect(rtDemand.first,
          IntervalTuple<num>(Hour.beginning(TZDateTime(IsoNewEngland.location, 2020)), 2719.842));
    });
  });
}


Future<void> main() async {
  initializeTimeZones();
  DbProd();

  var rootUrl = 'http://127.0.0.1:8080';
  await tests(rootUrl);


}