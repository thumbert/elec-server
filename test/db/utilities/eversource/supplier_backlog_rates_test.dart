library test.db.utilities.eversource.supplier_backlog_rates_test;

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/db/utilities/eversource/supplier_backlog_rates.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  group('Supplier backlog rates Db tests: ', () {
    var archive = getCtSupplierBacklogRatesArchive();
    test('get month from file', () {
      var file = archive.getFile(Month.utc(2023, 1), Utility.eversource);
      expect(archive.getMonthFromFile(file), Month.utc(2023, 1));
    });
    test('make url', () {
      var url = archive.getUrl(Month.utc(2015, 1), Utility.ui);
      expect(url.toString(),
          "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20January%202015%20UR.xlsx"
      );
      expect(archive.getUrl(Month.utc(2023, 4), Utility.eversource).toString(),
          'https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20April%202023%20ER.xlsx',
      );
      expect(archive.getUrl(Month.utc(2023, 5), Utility.eversource).toString(),
          'https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20May%202023%20ER.xlsx',
      );
      expect(archive.getUrl(Month.utc(2022, 5), Utility.ui).toString(),
          'https://energizect.com/media/5461',
      );
    });

    test('get all urls', () async {
      var months = Month.utc(2017, 1).upTo(Month.utc(2017, 12));
      for (var i=0; i<months.length; i++) {
        for (var utility in Utility.values) {
          print('i: $i, month: ${months[i]}, utility: $utility');
          var url = archive.getUrl(months[i], utility);
          print('url: $url');
          await archive.downloadFile(months[i], utility);
        }
      }
      expect(true, true);
    }, timeout: Timeout.factor(5));

    // test('read file for Eversource 2023-01', () {
    //   var file = archive.getFile(Month.utc(2023, 1), Utility.eversource);
    //   var data = archive.processFile(file);
    //   expect(data.length, 60);
    //   var x0 = data.first;
    //   expect(x0.keys.toSet(), {
    //     'month',
    //     'customerClass',
    //     'supplierName',
    //     'price',
    //     'kWh',
    //     'customerCount',
    //     'summary',
    //   });
    //   expect((x0['summary'] as Map).keys.toSet(),
    //       {'customerCount', 'kWh', 'volumeWeightedAveragePrice'});
    // });
  });
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}
