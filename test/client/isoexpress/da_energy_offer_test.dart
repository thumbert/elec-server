library test.client.da_energy_offer_test;

import 'dart:async';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:table/table.dart';
import 'package:elec_server/client/isoexpress/da_energy_offer.dart';

tests() async {
  Location location = getLocation('US/Eastern');
  var api = DaEnergyOffers(Client());
  group('DA Energy Offers client:', () {
    test('get energy offers for hour 2017-07-01 16:00:00', () async {
      var hour = Hour.beginning(TZDateTime(location, 2017, 7, 1, 16));
      var aux = await api.getDaEnergyOffers(hour);
      expect(aux.length, 731);
      expect(aux.first, {
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
      var data = await api.getDaEnergyOffersForAsset(41406, Date(2018,4,1), Date(2018,4,2));
      expect(data.length, 2);
    });
  });
}

identifyUnits() async {
  Location location = getLocation('US/Eastern');
  var api = DaEnergyOffers(Client());

  var start = Date(2017,11,1);
  var end = Date(2018,7,31);

  var assetsStart = (await api.assetsForDay(start))
      .map((e) => e['Masked Asset ID']).toSet();
  var assetsEnd = (await api.assetsForDay(end))
      .map((e) => e['Masked Asset ID']).toSet();
  //var newAssets = assetsEnd.difference(assetsStart);

  var newAssets = [86083, 25645, 54465, 80076, 52323].toSet();
  print('new assets:');
  print(newAssets);

//  var aux = newAssets.map((assetId) async {
//    return await api.getDaEnergyOffersForAsset(assetId, end, end);
//  }).toList();
//  var data = await Future.wait(aux);
//  print(data);

  /// get ecomax by assetId
//  var stack = await api.getGenerationStack(Hour.beginning(
//      TZDateTime(location, 2018,7,1,16)));
//  var ecoMax = stack.map((e) => {
//    'assetId': e['assetId'],
//    'Economic Maximum': e['Economic Maximum'],
//  }).toList();
//  ecoMax.sort((a,b) => -a['Economic Maximum'].compareTo(b['Economic Maximum']));
//  var uAssets = unique(ecoMax);
//  uAssets.forEach(print);

  /// get Masked Lead Participant ID when you know the Masked Asset ID
  var info = await api.assetsForDay(end);
  var aux = info.where((e) => newAssets.contains(e['Masked Asset ID'])).toList();
  aux.forEach(print);

  ///
  int maskedParticipantId = 902793;
  var data = await api.assetsForParticipantId(maskedParticipantId, Date(2017,1,1),
      Date(2018,7,1));
  //print(data);
  //data.forEach(print);

  var nest = Nest()
    ..key((e) => e['date'])
    ..rollup((List xs) => xs.length);
  var count = nest.map(data);
  count.entries.forEach(print);
  //print(count);




}









main() async {
  await initializeTimeZone();
  //await tests();

  await identifyUnits();

}
