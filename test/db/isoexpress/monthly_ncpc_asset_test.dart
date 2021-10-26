library test.db.isoexpress.monthly_ncpc_asset_test;

// import 'package:elec_server/api/isoexpress/api_isone_bindingconstraints.dart';
// import 'package:elec_server/client/isoexpress/binding_constraints.dart';
import 'package:elec_server/api/isoexpress/api_isone_monthly_ncpc_asset.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/monthly_ncpc_asset.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
void tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  var archive = MonthlyNcpcAssetArchive();
  group('Monthly NCPC by asset db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read file for 2019-01', () async {
      var file = archive.getFilename(Month.utc(2019, 1));
      var data = archive.processFile(file);
      expect(data.length, 481);
      expect(data.first, {
        'month': '2019-01',
        'assetId': 321,
        'daNcpc': 0,
        'rtNcpc': 628.87,
      });
    });
  });
  group('Monthly NCPC by asset API tests:', () {
    var api = MonthlyNcpcAsset(archive.db);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('Get NCPC for all assets Jan19-Mar19', () async {
      var res = await api.apiGetAllAssets('2019-01', '2019-03');
      expect(res.length, 44);
    }, solo: true);
    test('Get one NCPC payments for one asset', () async {
      var res = await api.apiGetAsset('1616', '2019-01', '2021-06');
      expect(res.length, 2);
    });
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
  DbProd();
  // await MonthlyNcpcAssetArchive().setupDb();

  // await prepareData();

  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
