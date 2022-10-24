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
import 'package:elec_server/src/db/isoexpress/zonal_demand.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  group('Api ISONE zonal demand tests', () {
    var api = ZonalDemand(DbProd.isoexpress);
    setUp(() async => await api.db.open());
    tearDown(() async => await api.db.close());
    test('get data for isone, 2017-01-01', () async {
      var data = await api.apiGetZonalDemand('isone', '20170101', '20170101');
      expect(data.length, 24);
      expect(data.first.keys.toSet(), {
        'hourBeginning',
        'DA_Demand',
        'RT_Demand',
        'DryBulb',
        'DewPoint',
      });
    });
    test('http get data for isone, 2017-01-01', () async {
      var url = '$rootUrl/isone/zonal_demand/v1/zone/isone/start/20170101/end/20170101';
      var res = await get(Uri.parse(url));
      var data = json.decode(res.body) as List;
      expect(data.length, 24);
      expect(data.first.keys.toSet(), {
        'hourBeginning',
        'DA_Demand',
        'RT_Demand',
        'DryBulb',
        'DewPoint',
      });
    });
  });
  group('Client ISONE zonal demand tests', () {
    var client = IsoneZonalDemand(Client());
    test('get isone rt demand', () async {
      var rtDemand = await client.getPoolDemand(Market.rt, Date.utc(2020, 1, 1), Date.utc(2020, 1, 1));
      expect(rtDemand.length, 24);
      expect(rtDemand.first,
          IntervalTuple<num>(Hour.beginning(TZDateTime(IsoNewEngland.location, 2020)), 11441.992));
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

  /// recreate the database (3 min)
  // await insertZonalDemand();

}