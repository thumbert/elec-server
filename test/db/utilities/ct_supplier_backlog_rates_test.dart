import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec_server/api/utilities/api_ct_supplier_backlog_rates.dart';
import 'package:elec_server/client/utilities/ct_supplier_backlog_rates.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  final archive = getCtSupplierBacklogRatesArchive();
  group('Supplier backlog rates Db tests: ', () {
    test('get month from file', () {
      var file = archive.getFile(Month.utc(2023, 1), Utility.eversource);
      expect(archive.getMonthFromFile(file), Month.utc(2023, 1));
    });
    test('get all urls', () async {
      await archive.getAllUrls();
      var months = Month.utc(2023, 1).upTo(Month.utc(2023, 7));
      for (var i = 0; i < months.length; i++) {
        for (var utility in Utility.values) {
          print('i: $i, month: ${months[i]}, utility: $utility');
          var url = archive.getUrl(months[i], utility);
          print('url: $url');
          await archive.downloadFile(months[i], utility);
        }
      }
      expect(true, true);
    }, timeout: Timeout.factor(5), skip: true);

    test('read all files from 2022-01 to 2023-07', () {
      var months = Month.utc(2023, 1).upTo(Month.utc(2023, 7));
      for (var month in months) {
        for (var utility in [Utility.eversource]) {
          print('Working on $utility month $month');
          var file = archive.getFile(month, utility);
          if (file.existsSync()) {
            var data = archive.processFile(file);
            var x0 = data.first;
            expect(
                x0.keys.toSet().containsAll({
                  'month',
                  'utility',
                  'customerClass',
                  'supplierName',
                  'price',
                  'kWh',
                  'summary',
                }),
                true);
            expect(
                (x0['summary'] as Map).keys.toSet().containsAll(
                    {'customerCount', 'averagePriceWeightedByCustomerCount'}),
                true);
          }
        }
      }
    }, skip: true);

    test('read file for Eversource 2023-01', () {
      var file = archive.getFile(Month.utc(2023, 1), Utility.eversource);
      var data = archive.processFile(file);
      expect(data.length, 60);
      var x0 = data.first;
      expect(x0.keys.toSet(), {
        'month',
        'utility',
        'customerClass',
        'supplierName',
        'price',
        'kWh',
        'summary',
      });
      expect((x0['summary'] as Map).keys.toSet(), {
        'customerCount',
        'averagePriceWeightedByCustomerCount',
        'kWh',
        'averagePriceWeightedByVolume'
      });
    });
  });

  group('Supplier backlog rates API tests:', () {
    var api = ApiCtSupplierBacklogRates(archive.dbConfig.db);
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('get Eversource data Sep24-Oct24', () async {
      var res = await api.getAllDataForOneUtility(
          Utility.eversource, Month.utc(2024, 9), Month.utc(2024, 10));
      expect(res.length, 126);
      var url =
          '$rootUrl/retail_suppliers/v1/ct/supplier_backlog_rates/utility/Eversource/start/2024-09/end/2024-10';
      var aux = await get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      var x0 = data.first as Map<String, dynamic>;
      expect(x0.keys.toSet(), {
        'month',
        'utility',
        'customerClass',
        'supplierName',
        'price',
        'kWh',
        'summary',
      });
    });

    test('get Eversource data Feb25 had some NaN', () async {
      var res = await api.getAllDataForOneUtility(
          Utility.eversource, Month.utc(2025, 2), Month.utc(2025, 2));
      expect(res.length, 62);
      var url =
          '$rootUrl/retail_suppliers/v1/ct/supplier_backlog_rates/utility/Eversource/start/2025-02/end/2025-02';
      var aux = await get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      var x0 = data.first as Map<String, dynamic>;
      expect(x0.keys.toSet(), {
        'month',
        'utility',
        'customerClass',
        'supplierName',
        'price',
        'kWh',
        'summary',
      });
    });
  });

  group('Supplier backlog rates Client tests:', () {
    var client = CtSupplierBacklogRates(Client(), rootUrl: rootUrl);
    test('get Eversource data Sep24-Oct24', () async {
      var data = await client.getBacklogForUtility(
          utility: Utility.eversource,
          start: Month.utc(2024, 9),
          end: Month.utc(2024, 10));
      expect(data.length, 126);
      var x0 = data.first;
      expect(x0.keys.toSet(), {
        'month',
        'utility',
        'customerClass',
        'supplierName',
        'price',
        'kWh',
        'summary',
      });
    });
    test('get Eversource data Sep24-Oct24', () async {
      var data = await client.getBacklogForUtility(
          utility: Utility.eversource,
          start: Month.utc(2024, 9),
          end: Month.utc(2024, 10));
      var x0 = data
          .where((e) =>
              e['supplierName'] == 'CONSTELLATION NEWENERGY RES' &&
              e['customerClass'] == 'Residential')
          .toList();
      expect(x0.length, 2);
      expect(x0.last['month'], '2024-10');
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  DbProd();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;

  await tests(rootUrl);
}
