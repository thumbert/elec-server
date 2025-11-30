import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  var archive = getIsoneDaEnergyOfferArchive();

  group('ISONE DA energy offers db tests: ', () {
    test('read json file 2024-11-01', () {
      var file = archive.getFilename(Date.utc(2024, 11, 1));
      var res = archive.processFile(file);
      expect(res.length, 21501);
      var x88115 = res
          .where((e) =>
              e.maskedAssetId == 88115 &&
              e.hour == Hour.beginning(TZDateTime(location, 2024, 11, 1)))
          .toList();
      expect(x88115.length, 2);
      expect(x88115.first.quantity, 0.1);
      expect(x88115.first.price, 0);
      expect(x88115.last.quantity, 4.4);
      expect(x88115.last.price, 0.01);
    });
    // test('DA energy offers report, DST day spring', () {
    //   var file = archive.getFilename(Date.utc(2017, 3, 12));
    //   var res = archive.processFile(file);
    //   expect(res.first['hours'].length, 23);
    // });
    // test('DA hourly lmp report, DST day fall', () {
    //   var file = archive.getFilename(Date.utc(2017, 11, 5));
    //   var res = archive.processFile(file);
    //   expect(res.first['hours'].length, 25);
    // });
  });

  // group('ISONE DA energy offers API tests: ', () {
  //   var api = DaEnergyOffers(archive.db, iso: Iso.newEngland);
  //   setUp(() async => await archive.db.open());
  //   tearDown(() async => await archive.db.close());
  //   test('get energy offers for one hour', () async {
  //     var data = await api.getEnergyOffers('20170701', '16');
  //     expect(data.length, 731);

  //     var a87105 = data.firstWhere((e) => e['assetId'] == 87105);
  //     expect(a87105['Economic Maximum'], 35);
  //     expect(a87105['quantity'], 9999);
  //   });
  //   test('get stack for one hour', () async {
  //     var data = await api.getGenerationStack('20170701', '16');
  //     expect(data.length, 696);
  //   });
  //   test('get assets one day', () async {
  //     var data = await api.assetsByDay('20170701');
  //     expect(data.length, 308);
  //   });
  //   test('get Economic Maximum for one day', () async {
  //     var data = await api.oneDailyVariable(
  //         'Economic Maximum', '20170701', '20170701');
  //     expect(data.length, 308);
  //   });
  //   test('get energy offers for one asset between a start/end date', () async {
  //     var data =
  //         await api.getEnergyOffersForAssetId('41406', '20170701', '20170702');
  //     expect(data.length, 2);
  //   });
  // });

  // group('ISONE DA energy offers client tests: ', () {
  //   var client =
  //       eo.DaEnergyOffers(http.Client(), iso: Iso.newEngland, rootUrl: rootUrl);
  //   test('get energy offers for hour 2017-07-01 16:00:00', () async {
  //     var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
  //     var aux = await client.getDaEnergyOffers(hour);
  //     expect(aux.length, 731);
  //     var e10393 = aux.firstWhere((e) => e['assetId'] == 10393);
  //     expect(e10393, {
  //       'assetId': 10393,
  //       'Unit Status': 'ECONOMIC',
  //       'Economic Maximum': 14.9,
  //       'price': -150,
  //       'quantity': 10.5,
  //     });
  //   });
  //   test('get generation stack for hour 2017-07-01 16:00:00', () async {
  //     var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
  //     var aux = await client.getGenerationStack(hour);
  //     expect(aux.length, 696);
  //     expect(aux.first, {
  //       'assetId': 10393,
  //       'Unit Status': 'ECONOMIC',
  //       'Economic Maximum': 14.9,
  //       'price': -150,
  //       'quantity': 10.5,
  //     });
  //   });
  //   test('get asset ids and participant ids for 2017-07-01', () async {
  //     var aux = await client.assetsForDay(Date.utc(2017, 7, 1));
  //     expect(aux.length, 308);
  //     aux.sort((a, b) =>
  //         (a['Masked Asset ID'] as int).compareTo(b['Masked Asset ID']));
  //     expect(aux.first, {
  //       'Masked Asset ID': 10393,
  //       'Masked Lead Participant ID': 698953,
  //     });
  //   });
  //   test('get energy offers for asset 41406 between 2 dates', () async {
  //     var data = await client.getDaEnergyOffersForAsset(
  //         41406, Date.utc(2017, 7, 1), Date.utc(2017, 7, 2));
  //     expect(data.length, 2);
  //   });
  //   test('get energy offers price/quantity timeseries for asset 41406 ',
  //       () async {
  //     var data = await client.getDaEnergyOffersForAsset(
  //         41406, Date.utc(2018, 4, 1), Date.utc(2018, 4, 1));
  //     var out = eo.priceQuantityOffers(data, iso: Iso.newEngland);
  //     expect(out.length, 5);
  //     expect(out.first.first.toString(),
  //         '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 15.44, quantity: 332}');
  //   });
  //   test('get average energy offers price timeseries for asset 41406 ',
  //       () async {
  //     var data = await client.getDaEnergyOffersForAsset(
  //         41406, Date.utc(2018, 4, 1), Date.utc(2018, 4, 1));
  //     var pqOffers = eo.priceQuantityOffers(data, iso: Iso.newEngland);
  //     var out = eo.averageOfferPrice(pqOffers);
  //     expect(out.length, 24);
  //     expect(out.first.toString(),
  //         '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 16.59470909090909, quantity: 550}');
  //   });

  //   test('get average energy offers price timeseries for asset 11515',
  //       () async {
  //     /// DOREEN, is unavailable for the entire term
  //     var data = await client.getDaEnergyOffersForAsset(
  //         11515, Date.utc(2023, 5, 1), Date.utc(2023, 5, 30));
  //     var pqOffers = eo.priceQuantityOffers(data, iso: Iso.newEngland);
  //     var out = eo.averageOfferPrice(pqOffers);
  //     expect(out.isEmpty, true);
  //   });

  //   test('get offers from DuckDb, make timeseries', () async {
  //     final term = Term.parse('1Apr24-2Apr24', IsoNewEngland.location);
  //     var offers = await eo.getEnergyOffers(
  //         iso: Iso.newEngland,
  //         market: Market.da,
  //         term: term,
  //         maskedAssetIds: [77459],
  //         rootUrl: dotenv.env['RUST_SERVER']!);
  //     expect(offers.length, 192); // 2 days * 4 segments * 24 hours = 192

  //     var xts = eo.makeTimeSeriesFromOffers(offers, Iso.newEngland);
  //     expect(xts.length, 4); // 4 segments
  //     var ts0 = xts.first;
  //     expect(ts0.first.interval,
  //         Hour.beginning(TZDateTime(IsoNewEngland.location, 2024, 4)));
  //     expect(ts0.first.value, {'quantity': 404.0, 'price': 67.04});

  //     expect(ts0.length, 24); // on 2Apr24 the unit became unavailable
  //   });

  //   test('get stack from DuckDb', () async {
  //     var stack = await eo.getStack(
  //         iso: Iso.newEngland,
  //         market: Market.da,
  //         hourBeginning: [
  //           TZDateTime(IsoNewEngland.location, 2024, 3, 1, 16),
  //           TZDateTime(IsoNewEngland.location, 2024, 4, 1, 16),
  //         ],
  //         rootUrl: dotenv.env['RUST_SERVER']!);
  //     expect(stack.length, 1553);
  //     final s0 = stack.first;
  //     expect(s0.keys.toSet(), {
  //       'masked_asset_id',
  //       'unit_status',
  //       'timestamp_s',
  //       'segment',
  //       'quantity',
  //       'price'
  //     });
  //   });
  // });

  // group('DuckDb functionality tests', () {
  //   late final Connection con;
  //   setUp(() {
  //     con = Connection(
  //         '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/energy_offers.duckdb',
  //         Config(accessMode: AccessMode.readOnly));
  //   });
  //   tearDown(() {
  //     con.close();
  //   });
  //   test('get offers for one unit', () {
  //     final term = Term.parse('1Jan23', IsoNewEngland.location);
  //     final offers = getEnergyOffers(con, term, Market.rt, [72020]);
  //     expect(offers.length, 120);
  //   });
  // });
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await tests('http://127.0.0.1:8080');
}
