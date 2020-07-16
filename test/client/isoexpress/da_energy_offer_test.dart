library test.client.da_energy_offer_test;

import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:table/table.dart';
import 'package:elec_server/client/isoexpress/da_energy_offer.dart';

void tests() async {
  var location = getLocation('America/New_York');
  var api = DaEnergyOffers(Client());
  group('DA Energy Offers client:', () {
    test('get energy offers for hour 2017-07-01 16:00:00', () async {
      var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
      var aux = await api.getDaEnergyOffers(hour);
      expect(aux.length, 731);
      var e10393 = aux.firstWhere((e) => e['assetId'] == 10393);
      expect(e10393, {
        'assetId': 10393,
        'Unit Status': 'ECONOMIC',
        'Economic Maximum': 14.9,
        'price': -150,
        'quantity': 10.5,
      });
    });
    test('get generation stack for hour 2017-07-01 16:00:00', () async {
      var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
      var aux = await api.getGenerationStack(hour);
      expect(aux.length, 696);
      expect(aux.first, {
        'assetId': 10393,
        'Unit Status': 'ECONOMIC',
        'Economic Maximum': 14.9,
        'price': -150,
        'quantity': 10.5,
      });
    });
    test('get asset ids and participant ids for 2017-07-01', () async {
      var aux = await api.assetsForDay(Date(2017, 7, 1));
      expect(aux.length, 308);
      aux.sort((a,b) => (a['Masked Asset ID'] as int).compareTo(b['Masked Asset ID']));
      expect(aux.first, {
        'Masked Asset ID': 10393,
        'Masked Lead Participant ID': 698953,
      });
    });
    test('get last day in db', () async {
      var date = await api.lastDate();
      expect(date is Date, true);
    });
    test('get energy offers for asset 41406 between 2 dates', () async {
      var data = await api.getDaEnergyOffersForAsset(41406, Date(2017, 7, 1),
          Date(2017, 7, 2));
      expect(data.length, 2);
    });
    test('get energy offers price/quantity timeseries for asset 41406 ',
        () async {
      var data = await api.getDaEnergyOffersForAsset(
          41406, Date(2018, 4, 1), Date(2018, 4, 1));
      var out = priceQuantityOffers(data);
      expect(out.length, 5);
      expect(
          out.first.first.toString(),
          '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 15.44, quantity: 332}');
    });
    test('get average energy offers price timeseries for asset 41406 ',
            () async {
          var data = await api.getDaEnergyOffersForAsset(
              41406, Date(2018, 4, 1), Date(2018, 4, 1));
          var pqOffers = priceQuantityOffers(data);
          var out = averageOfferPrice(pqOffers);
          expect(out.length, 24);
          expect(
              out.first.toString(),
              '[2018-04-01 00:00:00.000-0400, 2018-04-01 01:00:00.000-0400) -> {price: 16.59470909090909, quantity: 550}');
        });


  });
}


/// Get all the units
//totalMwByParticipant() async {
//  var api = DaEnergyOffers(Client());
//  var location = getLocation('America/New_York');
//  var hour = Hour.beginning(TZDateTime(location, 2016));
//
//  var eo = await api.getDaEnergyOffers(hour);
//  var grp = groupBy(eo, (e) => e['Masked Lead Participant ID']);
//  var out = [];
//  /// TODO: continue the implementation
//
//
//}


//identifyUnits() async {
//  var location = getLocation('America/New_York');
//  var api = DaEnergyOffers(Client());
//
//  var start = Date(2016, 1, 1);
//  var end = Date(2018, 7, 31);
//
//  var participantId = 591975;
//
//  var assetsStart =
//      (await api.assetsForDay(start))
//          .where((e) => e['Masked Lead Participant ID'] == participantId)
//          .map((e) => e['Masked Asset ID']).toSet();
//  var assetsEnd =
//      (await api.assetsForDay(end))
//          .where((e) => e['Masked Lead Participant ID'] == participantId)
//          .map((e) => e['Masked Asset ID']).toSet();
//  var newAssets = assetsEnd.intersection(assetsStart);
//  print(newAssets);
//
//
//
////  var newAssets = [86083, 25645, 54465, 80076, 52323].toSet();
////  print('new assets:');
////  print(newAssets);
//
////  var aux = newAssets.map((assetId) async {
////    return await api.getDaEnergyOffersForAsset(assetId, end, end);
////  }).toList();
////  var data = await Future.wait(aux);
////  print(data);
//
//  /// get ecomax by assetId
////  var stack = await api.getGenerationStack(Hour.beginning(
////      TZDateTime(location, 2018,7,1,16)));
////  var ecoMax = stack.map((e) => {
////    'assetId': e['assetId'],
////    'Economic Maximum': e['Economic Maximum'],
////  }).toList();
////  ecoMax.sort((a,b) => -a['Economic Maximum'].compareTo(b['Economic Maximum']));
////  var uAssets = unique(ecoMax);
////  uAssets.forEach(print);
//
////  /// get Masked Lead Participant ID when you know the Masked Asset ID
////  var info = await api.assetsForDay(end);
////  var aux =
////      info.where((e) => newAssets.contains(e['Masked Asset ID'])).toList();
////  aux.forEach(print);
////
////  ///
////  int maskedParticipantId = 591975;
////  var data = await api.assetsForParticipantId(
////      maskedParticipantId, Date(2017, 1, 1), Date(2018, 7, 1));
////  //print(data);
////  //data.forEach(print);
////
////  var nest = Nest()
////    ..key((e) => e['date'])
////    ..rollup((List xs) => xs.length);
////  var count = nest.map(data);
////  count.entries.forEach(print);
//  //print(count);
//}

void main() async {
  await initializeTimeZone();
  await tests();

//  await identifyUnits();
}
