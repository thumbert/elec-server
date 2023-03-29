library test.db.utilities.eversource.supplier_backlog_rates_test;

import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  group('Supplier backlog rates tests: ', () {
    var archive = RetailSuppliersOffersArchive();
    test('read file for Eversource 2023-01', () {

    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}