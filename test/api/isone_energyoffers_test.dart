library test.isone_energyoffers_test;

import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/api_isone_energyoffers.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';

ApiTest() async {
  Db db;
  DaEnergyOffers api;
  setUp(() async {
    db = new Db('mongodb://localhost/isoexpress');
    api = new DaEnergyOffers(db);
    await db.open();
  });
  tearDown(() async {
    await db.close();
  });
  group('api energy offers', () {
    test('get energy offers for one hour', () async {
      var data = await api.getEnergyOffers('20170701', '16');
      expect(data.length, 733);

//      var a87105 = data.firstWhere((Map e) => e['assetId'] == 87105);
//      expect(a87105['Economic Maximum'], 35);
//      expect(a87105['quantity'], 9999);
    });
    test('get stack for one hour', () async {
      var data = await api.getGenerationStack('20170701', '16');
      //data.forEach(print);
      expect(data.length, 698);

      Map fixedData = data.firstWhere((Map e) => e['assetId'] == 87105);
      print(fixedData);
    });
  });
}

insertDays(Month month) async {
  var archive = new DaEnergyOfferArchive();
  await archive.dbConfig.db.open();
  for (var day in month.days()) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}


main() async {
  await initializeTimeZone();
  await ApiTest();

  // insertDays(new Month(2017, 12));

}
