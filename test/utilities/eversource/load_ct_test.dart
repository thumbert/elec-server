library test.utilities.eversource.customer_counts;

import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/utilities/eversource/load_ct.dart';


loadTest() async {
  EversourceCtLoadArchive archive;
  group('eversource ct loads', (){
    setUp(()async {
      archive =  EversourceCtLoadArchive();
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

int _getYear(String link) {
  var reg = RegExp('(.*)actual-load(.*).xlsx(.*)');
}



updateDb() async {
  var archive = EversourceCtLoadArchive();

  var url = 'https://www.eversource.com/content/ct-c/about/about-us/doing-business-with-us/energy-supplier-information/wholesale-supply-(connecticut)';
  var links = await getLinks(url, patterns: ['actual-load-', 'actual-loads-']);
  links.forEach(print);

  await archive.dbConfig.db.open();
  var futs = links.map((link) async {
    await archive.downloadFile(link);
    var data = archive.readXlsx(archive.);
    return await archive.insertData(data);
  });
  await Future.wait(futs);
  await archive.dbConfig.db.close();
}


insertYears({List<int> years}) async {
  years ??= [2014, 2015, 2016, 2017, 2018];
  var archive = EversourceCtLoadArchive();
  await archive.dbConfig.db.open();
  for (var year in years) {
    await archive.downloadFile(year);
    var data = archive.readXlsx(archive.getFile(year));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();
}




main() async {
  await initializeTimeZone();
  //await EversourceCtLoadArchive().setup();

  //await loadTest();

  await updateDb();

  //await insertYears();

}
