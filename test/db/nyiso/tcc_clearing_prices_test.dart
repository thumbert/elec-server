import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:elec/ftr.dart';
import 'package:elec_server/api/nyiso/api_nyiso_tcc_clearing_prices.dart';
import 'package:elec_server/client/ftr_clearing_prices.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl) async {
  var archive = getNyisoTccClearingPriceArchive();
  group('NYISO Tcc clearing prices db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read G22-J22', () async {
      var data =
          archive.processFile(File('${archive.dir}clearingprices_G22-J22.csv'));
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
          .processFile(File('${archive.dir}clearingprices_K21-2Y-R1.csv'));
      expect(data.length, 358);
      expect(data.first, {
        'auctionName': 'K21-2Y-R1',
        'ptid': 23512,
        'clearingPriceHour': 10.990031963470319,
      });
    });
    test('get last auctionId', () {
      var id = archive.lastAuctionId();
      expect(id > 100, true);
    });

    test('get all auctionIds from web', () async {
      var ids = await archive.getAuctionIdsPosted();
      expect(ids.length > 400, true);
      expect(ids.contains(3366), true);
    });

    // test('download auction results', () async {
    //   var auctionId = 3366;
    //   var file = File(join(archive.dir, 'clearingprices_$auctionId.csv'));
    //   await archive.downloadPrices(auctionId);
    //   var data = archive.processFile(file);
    //   expect(data.length, 2142);
    //   expect(data.first, {
    //     'auctionName': 'X22',
    //     'ptid': 23512,
    //     'clearingPriceHour': 43.19801664355062,
    //   });
    // }, solo: true);
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
      expect(
          cpG22.keys.toSet(), {'auctionName', 'bucket', 'clearingPriceHour'});
      expect(cpG22['clearingPriceHour'], 9.857217261904761);
    });
    test('Get all clearing prices several nodes', () async {
      var url = '$rootUrl/nyiso/tcc_clearing_prices/v1/ptids/61752,61758';
      var aux = await http.get(Uri.parse(url));
      var res = json.decode(aux.body) as List;
      expect(res.length > 10, true);
      var cpG22 = res
          .firstWhere((e) => e['auctionName'] == 'F21' && e['ptid'] == 61752);
      expect(cpG22.keys.toSet(),
          {'auctionName', 'bucket', 'ptid', 'clearingPriceHour'});
      expect(cpG22['clearingPriceHour'], 1.7079301075268818);
    });
    test('Get all clearing prices for one auction, G22', () async {
      var res = await api.clearingPricesAuction('G22');
      expect(res.length, 358);
    });
    test('Get all the auction names', () async {
      var url = '$rootUrl/nyiso/tcc_clearing_prices/v1/auctions';
      var aux = await http.get(Uri.parse(url));
      var res = json.decode(aux.body) as List;
      expect(res.length > 10, true);
      expect(res.contains('F21'), true);
    });
  });
  group('TCC clearing prices client tests:', () {
    var client =
        FtrClearingPrices(http.Client(), iso: Iso.newYork, rootUrl: rootUrl);
    test('get clearing prices for one node', () async {
      var cp = await client.getClearingPricesForPtid(61752);
      var x = cp.firstWhere((e) => e['auctionName'] == 'F21');
      expect(x, {
        'auctionName': 'F21',
        'bucket': '7x24',
        'clearingPriceHour': 1.7079301075268818,
      });
    });
    test('get clearing prices for one node that doesn\'t exist', () async {
      var cp = await client.getClearingPricesForPtid(1);
      expect(cp.isEmpty, true);
    });
    test('get clearing prices for two nodes', () async {
      var cp = await client.getClearingPricesForPtids([61752, 61758]);
      var xs = cp.where((e) => e['auctionName'] == 'F21').toList();
      expect(xs.length, 2);
      expect(xs.firstWhere((e) => e['ptid'] == 61752), {
        'auctionName': 'F21',
        'ptid': 61752,
        'bucket': '7x24',
        'clearingPriceHour': 1.7079301075268818,
      });
    });
    test('get all clearing prices for one auction', () async {
      var xs = await client.getClearingPricesForAuction('F21');
      expect(xs.length, 361);
      expect(xs.firstWhere((e) => e['ptid'] == 61752), {
        'ptid': 61752,
        'bucket': '7x24',
        'clearingPriceHour': 1.7079301075268818,
      });
    });
    test('get all auction names from 2020-12-14', () async {
      var xs = await client.getAuctions(
          startDate: Date(2020, 12, 14, location: NewYorkIso.location));
      expect(xs.contains(FtrAuction.parse('J20', iso: Iso.newYork)), false);
      expect(xs.contains(FtrAuction.parse('J21', iso: Iso.newYork)), true);
      expect(xs.contains(FtrAuction.parse('Z21', iso: Iso.newYork)), true);
      expect(xs.contains(FtrAuction.parse('F22', iso: Iso.newYork)), true);
      expect(
          xs.contains(FtrAuction.parse('K21-2Y-R1Spring21', iso: Iso.newYork)),
          true);
      expect(
          xs.contains(FtrAuction.parse('X21-1Y-R1Autumn21', iso: Iso.newYork)),
          true);
    });
  });
}

void main() async {
  initializeTimeZones();
  DbProd();
  dotenv.load('.env/test.env');
  var rootUrl = dotenv.env['ROOT_URL']!;
  tests(rootUrl);
}
