library test.utilities.eversource.customer_counts;

import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/utilities/eversource/load_ct.dart';

loadTest() async {
  late EversourceCtLoadArchive archive;
  group('eversource ct loads', (){
    setUp(()async {
      archive =  EversourceCtLoadArchive();
      await archive.dbConfig.db.open();
    });
    tearDown(()async {
      await archive.dbConfig.db.close();
    });
    test('read year 2019', () async {
      int year = 2019;
      var file = archive.getFile(year);
      //if (!file.existsSync()) await archive.downloadFile(year);
      var data = archive.readXlsx(file);
      expect(data.length, 365);
      expect(data.first.length, 4);
      expect(data.first['load'].first.keys.length, 7);
    });
  });
}


updateDb() async {
  var archive = EversourceCtLoadArchive();

  var url = 'https://www.eversource.com/content/ct-c/about/about-us/doing-business-with-us/energy-supplier-information/wholesale-supply-(connecticut)';
  var links = await getLinks(url, patterns: ['actual-load-', 'actual-loads-']);
  links.forEach(print);

  var years = links.map((link) => {'year': getYear(link), 'link': link});

  await archive.dbConfig.db.open();
  for (var e in years) {
    await archive.downloadFile(e['link'] as String);
    var data = archive.readXlsx(archive.getFile(e['year'] as int?));
    await archive.insertData(data);
  }
  await archive.dbConfig.db.close();

}


main() async {
  await initializeTimeZone();
  //await EversourceCtLoadArchive().setup();

  //await loadTest();

  await updateDb();
}
