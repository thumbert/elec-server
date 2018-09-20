library test.customer_counts;

import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/utilities/eversource/load_ct.dart';


loadTest() async {
  EversourceCtLoadArchive archive;
  group('eversource ct loads', (){
    setUp(()async {
      archive = new EversourceCtLoadArchive();
      await archive.dbConfig.db.open();
    });
    tearDown(()async {
      await archive.dbConfig.db.close();
    });
    test('read year 2014', () async {
      int year = 2014;
      var file = archive.getFile(year);
      if (!file.existsSync()) await archive.downloadFile(year);
      var data = archive.readXlsx(file);
      expect(data.length, 365);
      expect(data.first.length, 4);
      expect(data.first['load'].first.keys.length, 7);
    });
  });
}

insertYears({List<int> years}) async {
  years ??= [2014, 2015, 2016, 2017, 2018];
  EversourceCtLoadArchive archive = new EversourceCtLoadArchive();
  await archive.dbConfig.db.open();
  for (var year in years) {
    await archive.downloadFile(year);
    List data = archive.readXlsx(archive.getFile(year));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}


apiTest() async {
//  var api = new ApiCustomerCounts(config.db);
//
//  await config.db.open();
//  //var res = await api.apiKwhTown('Attleboro');
//  //var res = await api.apiKwhZoneRateClass('SEMA', 'R1');
//  var res = await api.getAvailableTowns();
//  res.forEach(print);
//
//
//  await config.db.close();
}


main() async {
  await initializeTimeZone();
  //await new EversourceCtLoadArchive(dir: dir).setup();

  //await loadTest();

  await insertYears();

//  await apiTest();
}
