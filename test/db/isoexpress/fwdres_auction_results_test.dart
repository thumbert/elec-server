library test.db.isoexpress.fwdres_auction_results_test;

import 'dart:convert';

import 'package:elec_server/api/isoexpress/api_fwdres_auction_results.dart'
    as api;
import 'package:elec_server/src/db/isoexpress/fwdres_auction_results.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = FwdResAuctionResultsArchive();
  group('FwdRes Auction Results db tests:', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('make urls', () async {
      expect(archive.getUrl('Summer 20'),
          'https://www.iso-ne.com/static-assets/documents/2020/04/forward_reserve_auction_results.csv');
    });
    test('read file for Summer 20', () async {
      var file = archive.getFilename('Summer 20');
      var data = archive.processFile(file);
      expect(data.length, 8);
      expect(data.first.keys.toSet(), {
        'auctionName',
        'reserveZoneId',
        'reserveZoneName',
        'product',
        'mwOffered',
        'mwCleared',
        'clearingPrice',
        'proxyPrice',
      });
      expect(data.first, {
        'auctionName': 'Summer 20',
        'reserveZoneId': 7000,
        'reserveZoneName': 'ROS',
        'product': 'TMNSR',
        'mwOffered': 2214.46,
        'mwCleared': 1297.83,
        'clearingPrice': 1249.0,
        'proxyPrice': 1249.0,
      });
    });
    test('read file for Summer 16', () async {
      // file changes format for 'Procurement Period Begin Month' column!
      var file = archive.getFilename('Summer 16');
      var data = archive.processFile(file);
      expect(data.length, 8);
    });
  });
  //
  //
  group('FwdRes Auction Results API tests:', () {
    test('Get all results', () async {
      var res = await http.get(
          Uri.parse('$rootUrl/fwdres_auction_results/v1/all'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      var x0 = data.firstWhere((e) =>
          e['auctionName'] == 'Summer 20' &&
          e['reserveZoneId'] == 7000 &&
          e['product'] == 'TMNSR');
      expect(x0, {
        'auctionName': 'Summer 20',
        'reserveZoneId': 7000,
        'reserveZoneName': 'ROS',
        'product': 'TMNSR',
        'mwOffered': 2214.46,
        'mwCleared': 1297.83,
        'clearingPrice': 1249.0,
        'proxyPrice': 1249.0,
      });
    });
  });
  //
  //
  // group('Binding constraints client tests:', () {
  //   var client = BindingConstraints(http.Client(),
  //       iso: Iso.newEngland, rootUrl: rootUrl);
  //   test('get da binding contraints', () async {
  //     var term = Term.parse('1Jan17-2Jan17', location);
  //     var res = await client.getDaBindingConstraints(term.interval);
  //     var nyne = res['NYNE']!;
  //     expect(nyne.length, 2);
  //   });
  //   test('get da binding constraints data for 3 days, details', () async {
  //     var interval = Interval(
  //         TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2017, 1, 3));
  //     var aux = await client.getDaBindingConstraintsDetails(interval);
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
