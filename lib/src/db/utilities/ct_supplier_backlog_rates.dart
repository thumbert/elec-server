library db.utilities.eversource.supplier_backlog_rates;

import 'dart:io';

import 'package:elec_server/client/utilities/ct_supplier_backlog_rates.dart';
import 'package:html/parser.dart' show parse;
import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:more/more.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:timezone/timezone.dart';

/// See https://energizect.com/rate-board-residential-standard-service-generation-rates
/// Each month has customer counts by competitive provider

class CtSupplierBacklogRatesArchive {
  CtSupplierBacklogRatesArchive({ComponentConfig? dbConfig, String? dir}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1',
            dbName: 'retail_suppliers',
            collectionName: 'ct_backlog_rates');
    this.dir = dir ?? '$baseDir../SupplierBacklogRates/CT/Raw/';
  }

  late final ComponentConfig dbConfig;
  late final String dir;

  static List<Map<String, dynamic>> allLinks = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> processFile(File file) {
    var name = path.basename(file.path).split('_').last.replaceAll('.xlsx', '');
    var utility = Utility.parse(name);

    return switch (utility) {
      Utility.eversource => _processFileEversource(file),
      Utility.ui => _processFileUi(file),
    };
  }

  List<Map<String, dynamic>> _processFileEversource(File file) {
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);

    var month = getMonthFromFile(file);
    var monthName = DateFormat('MMMM yyyy').format(month.start);
    var customerClass = {
      '$monthName Residential': 'Residential',
      '$monthName Residential IRAs': 'Residential IRA',
      '$monthName Residential IRA': 'Residential IRA',
      '$monthName C&I': 'C&I',
      '$monthName StLgt': 'StreetLights',
    };

    /// starting in 2022-11, Eversource started to publish the kWhs
    final hasKwh = month.isAfter(Month.utc(2022, 10));

    var out = <Map<String, dynamic>>[];
    for (var tabName in decoder.tables.keys) {
      final hasHardshipStatus =
          month.isAfter(Month.utc(2024, 11)) && tabName.contains('Residential');

      var table = decoder.tables[tabName]!;

      var data = <Map<String, dynamic>>[];
      for (var row in table.rows.skip(1)) {
        num? count = (hasKwh) ? row[4] : row[3];
        if (count == 0 || count == null) {
          continue;
        }
        late bool hardship;
        if (hasHardshipStatus) {
          var r5 = (row[5] as String).trim();
          hardship = r5 == 'Y'
              ? true
              : r5 == 'N'
                  ? false
                  : throw StateError(
                      'Hardship status ${row[5]} not supported!');
        }
        data.add({
          'code': row[0] as String,
          'supplierName': (row[1] as String).trim(),
          'price': row[2] as num,
          if (hasKwh) 'kWh': row[3] as num,
          'customerCount': count.round(),
          if (hasHardshipStatus) 'hardship': hardship,
        });
      }

      // aggregate data by supplier
      var groups = groupBy(data, (e) => e['supplierName']);
      for (var supplierName in groups.keys) {
        var xs = groups[supplierName]!;
        var totalCustomerCount = sum(xs.map((e) => e['customerCount']));
        late num avgPriceHardship;
        if (hasHardshipStatus) {
          avgPriceHardship = sum(xs
                  .where((e) => e['hardship'])
                  .map((e) => e['customerCount'] * e['price'])) /
              sum(xs
                  .where((e) => e['hardship'])
                  .map((e) => e['customerCount']));
        }
        var avgPrice = sum(xs.map((e) => e['customerCount'] * e['price'])) /
            totalCustomerCount;

        var one = {
          'month': month.toIso8601String(),
          'utility': 'Eversource',
          'customerClass': customerClass[tabName.trim()]!,
          'supplierName': (supplierName as String).toUpperCase(),
          'price': xs.map((e) => e['price']).toList(),
          'summary': {
            'customerCount': totalCustomerCount,
            if (hasHardshipStatus)
              'hardshipCustomerCount': sum(xs
                  .where((e) => e['hardship'])
                  .map((e) => e['customerCount'])),
            if (avgPrice.isFinite)
              'averagePriceWeightedByCustomerCount': avgPrice,
            if (hasHardshipStatus && avgPriceHardship.isFinite)
              'averagePriceWeightedByCustomerCountForHardshipCustomers':
                  avgPriceHardship,
          }
        };
        if (hasKwh) {
          one['kWh'] = xs.map((e) => e['kWh']).toList();
          var totalKWh = sum(xs.map((e) => e['kWh']));
          var avgPriceWeightedByVolume =
              sum(xs.map((e) => e['kWh'] * e['price'])) / totalKWh;
          one['summary'] = <String, dynamic>{
            ...one['summary'] as Map,
            'kWh': totalKWh,
            if (avgPriceWeightedByVolume.isFinite)
              'averagePriceWeightedByVolume': avgPriceWeightedByVolume,
          };
        }
        out.add(one);
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _processFileUi(File file) {
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);

    var month = getMonthFromFile(file);
    var monthName = DateFormat('MMMM yyyy').format(month.start);
    var customerClass = {
      '$monthName Residential': 'Residential',
      '$monthName Residential IRAs': 'Residential IRA',
      '$monthName C&I': 'C&I',
      'Residential': 'Residential',
      'Residential IRA': 'Residential IRA',
      'Reversals Residential': 'Reversals Residential',
    };

    var out = <Map<String, dynamic>>[];
    for (var tabName in decoder.tables.keys) {
      var table = decoder.tables[tabName]!;

      /// starting in 2022-10, UI started to publish the kWhs
      var hasKwh = month.isBefore(Month.utc(2022, 10)) ? false : true;
      var data = <Map<String, dynamic>>[];
      for (var row in table.rows.skip(1)) {
        if (row[1] is! num) continue;
        if (tabName == 'Residential ' &&
            month == Month.utc(2022, 10) &&
            row[3] is! num) {
          /// data is messed up for this month, at the bottom of the tab!
          data.add({
            'supplierName': row[0] as String,
            'price': row[1] as num,
            'kWh': row[2] * 350.0, // making this up!
            'customerCount': row[2] as int,
          });
        } else {
          data.add({
            'supplierName': row[0] as String,
            'price': row[1] as num,
            if (hasKwh) 'kWh': row[4] as num,
            'customerCount': (hasKwh) ? row[3] as int : row[2] as int,
          });
        }
      }
      var groups = groupBy(data, (e) => e['supplierName']);
      for (var supplierName in groups.keys) {
        var xs = groups[supplierName]!;
        out.add({
          'month': month.toIso8601String(),
          'utility': 'UI',
          'customerClass': customerClass[tabName.trim()]!,
          'supplierName': (supplierName as String).toUpperCase(),
          'price': xs.map((e) => e['price']).toList(),
          if (hasKwh) 'kWh': xs.map((e) => e['kWh']).toList(),
          'customerCount': xs.map((e) => e['customerCount']).toList(),
          'summary': {
            'customerCount': sum(xs.map((e) => e['customerCount'])),
            if (hasKwh) 'kWh': sum(xs.map((e) => e['kWh'])),
            'averagePriceWeightedByCustomerCount':
                mean(xs.map((e) => e['customerCount'] * e['price'])),
            if (hasKwh)
              'averagePriceWeightedByVolume':
                  mean(xs.map((e) => e['kWh'] * e['price'])),
          },
        });
      }
    }

    return out;
  }

  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
      var groups =
          groupBy(data, (e) => (e['month'], e['utility'], e['customerClass']));
      for (var entry in groups.entries) {
        await dbConfig.coll.remove({
          'month': entry.key.$1,
          'utility': entry.key.$2,
          'customerClass': entry.key.$3,
        });
        await dbConfig.coll.insertAll(entry.value); // insert all suppliers
        print('--->  Inserted ${entry.key} successfully');
      }
    } catch (e) {
      print('XXX $e');
      return Future.value(1);
    }
    return Future.value(0);
  }

  /// Download an xlsx file
  Future downloadFile(Month month, Utility utility) async {
    var url = getUrl(month, utility);
    if (url != null) {
      var res = await get(url);
      if (res.statusCode == 200) {
        var fileOut = getFile(month, utility);
        fileOut.writeAsBytesSync(res.bodyBytes);
      } else {
        throw StateError('Failed to download file for $utility and $month');
      }
    }
  }

  File getFile(Month month, Utility utility) {
    return File(
        '$dir${month.year}/${month.toIso8601String()}_${utility.toString()}.xlsx');
  }

  /// Get all urls and cache them ...
  Future<List<Map<String, dynamic>>> getAllUrls() async {
    var browser = await puppeteer.launch();
    var page = await browser.newPage();

    await page.goto(
        'https://energizect.com/rate-board-residential-standard-service-generation-rates');
    var content = await page.content;
    await browser.close();
    var document = parse(content);

    /// current year links
    var divs1 = document.querySelectorAll('div.coh-column div.coh-container '
        'div.coh-accordion-tabs-content p a');

    /// all historical years except the current year
    var divs2 = document.querySelectorAll('div.coh-row-inner div.coh-container '
        'div.coh-accordion-tabs-content div table tr td a');

    var res = <Map<String, dynamic>>[];
    for (var e in [...divs1, ...divs2]) {
      var monthName = e.nodes.first.text;
      var href = e.attributes['href'];
      if (monthName != null && href != null) {
        String? utility;
        if (path.basename(href).endsWith('ER.xlsx')) {
          utility = 'Eversource';
        } else if (path.basename(href).endsWith('UR.xlsx')) {
          utility = 'UI';
        }
        if (utility != null) {
          try {
            var month = Month.parse(monthName, location: UTC);
            res.add({
              'month': month.toIso8601String(),
              'utility': utility,
              'url': href,
            });
          } catch (e) {
            print('monthName: $monthName, href: $href');
          }
        }
      }
    }

    /// sort by month and utility
    const natural = naturalComparable<String>;
    var byMonth = natural.onResultOf<Map>((Map e) => e['month']);
    var byUtility = natural.onResultOf<Map>((Map e) => e['utility']);
    var ordering = byMonth.thenCompare(byUtility);
    res.sort(ordering);

    allLinks = [...res];
    return res;
  }

  /// Need to navigate here:
  ///   https://energizect.com/rate-board-residential-standard-service-generation-rates
  ///
  /// Return an url or null if the file is not on the website.
  Uri? getUrl(Month month, Utility utility) {
    assert(month.location.name == 'UTC');

    /// skip all exceptions!
    if (exceptions.contains((utility, month))) return null;

    if (allLinks.isNotEmpty) {
      var es = allLinks.firstWhereOrNull((e) =>
          e['month'] == month.toIso8601String() &&
          e['utility'] == utility.toString());
      var url = es?['url'] as String?;

      /// check the special urls ... there are plenty!
      var sUrl = specialUrls.firstWhereOrNull((e) =>
          e['month'] == month.toIso8601String() &&
          e['utility'] == utility.toString());
      if (sUrl != null) {
        url = sUrl['url'] as String;
        return Uri.parse(url);
      } else {
        return Uri.parse(url!);
      }
    } else {
      throw StateError('Please run getAllUrls() first!');
    }
  }

  /// Filename is something like '2023-03_Eversource.xlsx'
  Month getMonthFromFile(File file) {
    var x = path.basename(file.path);
    return Month.parse(x.substring(0, 7), location: UTC);
  }

  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'month': 1,
      'utility': 1,
      'customerClass': 1,
    });
    await dbConfig.db.close();
  }
}

/// Broken urls!  They look like links on the page, but they are not correct.
/// Reports have not been published for these months!
final exceptions = [
  (Utility.eversource, Month.utc(2018, 1)),
  (Utility.eversource, Month.utc(2018, 8)),
  (Utility.eversource, Month.utc(2018, 9)),
  (Utility.eversource, Month.utc(2018, 10)),
  (Utility.eversource, Month.utc(2019, 12)),
  //
  (Utility.ui, Month.utc(2021, 8)),
  (Utility.ui, Month.utc(2022, 4)),
];

final specialUrls = [
  {
    "month": "2017-09",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20September%202017%20ER_0.xlsx",
  },
  //
  // 2018
  //
  {
    "month": "2018-02",
    "utility": "Eversource",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20February%202018%20UR.xlsx",
  },
  {
    "month": "2018-02",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20February%202018%20UR_0.xlsx",
  },
  {
    "month": "2018-12",
    "utility": "UI",
    "url": "https://energizeconn.prod.acquia-sites.com/media/1561",
  },
  //
  // 2019
  //
  {
    "month": "2019-01",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20January%202019%20UR_1.xlsx",
  },
  {
    "month": "2019-09",
    "utility": "Eversource",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier Billed Rates - September 2019 ER.xlsx",
  },
  //
  // 2020
  //
  {
    "month": "2020-01",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20January%202020%20ER_0.xlsx",
  },
  {
    "month": "2020-08",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20August%202020%20UR%20%281%29.xlsx",
  },
  //
  // 2021
  //
  {
    "month": "2021-01",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20January%202021%20UR_0.xlsx",
  },
  //
  // 2022
  //
  {
    "month": "2022-01",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20January%202022%20UR_0.xlsx",
  },
  {
    "month": "2022-01",
    "utility": "Eversource",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20January%202022%20ER.xlsx",
  },
  {
    "month": "2022-02",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20February%202022%20UR_0.xlsx",
  },
  {
    "month": "2022-02",
    "utility": "Eversource",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20February%202022%20ER.xlsx",
  },
  {
    "month": "2022-03",
    "utility": "Eversource",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20March%202022%20ER.xlsx",
  },
  {
    "month": "2022-04",
    "utility": "UI",
    "url":
        "https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fenergizect.com%2Fsites%2Fdefault%2Ffiles%2F2022-07%2FSupplier%2520Billed%2520Rates%2520-%2520April%25202022%2520UR.xlsx&wdOrigin=BROWSELINK",
  },
  {
    "month": "2022-05",
    "utility": "Eversource",
    "url":
        "https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20May%202022%20ER.xlsx",
  },
  {
    "month": "2022-05",
    "utility": "UI",
    "url": "https://energizect.com/media/5461",
  },
  {
    "month": "2022-06",
    "utility": "Eversource",
    "url": "https://energizect.com/media/5446",
  },
  {
    "month": "2022-06",
    "utility": "UI",
    "url": "https://energizect.com/media/5466",
  },
  {
    "month": "2022-07",
    "utility": "Eversource",
    "url": "https://energizect.com/media/5451",
  },
  {
    "month": "2022-07",
    "utility": "UI",
    "url": "https://energizect.com/media/5471",
  },
  {
    "month": "2022-08",
    "utility": "Eversource",
    "url": "https://energizect.com/media/5456",
  },
  {
    "month": "2022-08",
    "utility": "UI",
    "url": "https://energizect.com/media/5476",
  },
  {
    "month": "2022-09",
    "utility": "Eversource",
    "url": "https://energizect.com/media/5826",
  },
  {
    "month": "2022-09",
    "utility": "UI",
    "url": "https://energizect.com/media/5836",
  },
];
