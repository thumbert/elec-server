library test.db.nyiso.tcc_clearing_prices_test;

import 'dart:io';

import 'package:elec/elec.dart';
import 'package:elec_server/api/nyiso/api_nyiso_tcc_clearing_prices.dart';
import 'package:elec_server/src/db/nyiso/tcc_clearing_prices.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  var archive = NyisoTccClearingPrices();
  group('NYISO Tcc clearing prices db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read G22-J22', () async {
      var data =
          archive.processFile(File(archive.dir + 'clearingprices_G22-J22.csv'));
      expect(data.length, 1074);
      expect(data.first, {
        'auctionName': 'G22',
        'ptid': 23512,
        'clearingPriceHour': 55.99744047619048,
      });
      // the Feb bopp file has actually 3 auctions in the file
      var n23512 = data.where((e) => e['ptid'] == 23512).toList();
      expect(n23512.length, 3);
      expect(n23512.map((e) => e['auctionName']).toList(), [
        'G22',
        'H22-boppG22',
        'J22-boppG22',
      ]);
    });

    test('read K21-2Y-R1', () async {
      var data = archive
          .processFile(File(archive.dir + 'clearingprices_K21-2Y-R1.csv'));
      expect(data.length, 1074);
      expect(data.first, {
        'auctionName': 'K21-2Y-R1',
        'ptid': 23512,
        'clearingPriceHour': 10.990031963470319,
      });
    });
  });
  group('TCC clearing prices API tests:', () {
    var api = ApiNyisoTccClearingPrices(
      archive.db,
    );
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('Get all clearing prices for one node, Zone A', () async {
      var res = await api.clearingPricesPtid(61752);
      expect(res.length > 10, true);
      var cpG22 = res.firstWhere((e) => e['auctionName'] == 'G22');
      expect(cpG22['clearingPriceHour'], 9.857217261904761);
    });
    test('Get all clearing prices for one auction, G22', () async {
      var res = await api.clearingPricesAuction('G22');
      expect(res.length, 358);
    });
    // test('Get cp, sp for a list of auctions', () async {
    //   var res = await api.cpsp(61752, 61758, 'G22,H22-boppG22,J22-boppG22');
    //   expect(res.length, 3);
    // }, solo: true);
  });
  // group('Binding constraints client tests:', () {
  //   var client = BindingConstraintsApi(http.Client(), rootUrl: rootUrl);
  //   test('get da binding constraints data for 3 days', () async {
  //     var interval = Interval(
  //         TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2017, 1, 3));
  //     var aux = await client.getDaBindingConstraints(interval);
  //     expect(aux.length, 44);
  //     var first = aux.first;
  //     expect(first, {
  //       'Constraint Name': 'SHFHGE',
  //       'Contingency Name': 'Interface',
  //       'Interface Flag': 'Y',
  //       'Marginal Value': -7.31,
  //       'hourBeginning': '2017-01-01 00:00:00.000-0500',
  //     });
  //   });
  //   test('get all occurrences of constraint Paris', () async {
  //     var name = 'PARIS   O154          A LN';
  //     var aux = await client.getDaBindingConstraint(
  //         name, Date.utc(2017, 1, 5), Date.utc(2017, 1, 6));
  //     expect(aux.length, 2);
  //   });
  //   test('get constraint indicator', () {});
  // });
}

void main() async {
  initializeTimeZones();
  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
