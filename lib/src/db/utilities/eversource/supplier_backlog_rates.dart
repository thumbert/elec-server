library db.utilities.eversource.supplier_backlog_rates;

import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/src/utils/string_extensions.dart';
import 'package:intl/intl.dart';
import 'package:more/more.dart';
import 'package:more/ordering.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:timezone/timezone.dart';

/// See https://energizect.com/rate-board-residential-standard-service-generation-rates
/// Each month has customer counts by competitive provider

enum Utility {
  eversource('Eversource'),
  ui('UI');

  const Utility(this._value);
  final String _value;

  static Utility parse(String x) {
    return switch (x) {
      'Eversource' => eversource,
      'UI' => ui,
      _ => throw ArgumentError('Don\'t know how to parse $x'),
    };
  }

  @override
  String toString() => _value;
}

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

  List<Map<String, dynamic>> processFile(File file) {
    if (path.basename(file.path) == '2019-12_Eversource.xlsx') {
      // missing data
      return <Map<String,dynamic>>[];
    }
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    print(decoder.tables.keys);

    var month = getMonthFromFile(file);
    var monthName = DateFormat('MMMM yyyy').format(month.start);
    var tableNames = {
      '$monthName Residential': 'Residential',
      '$monthName Residential IRAs': 'Residential IRA',
      '$monthName C&I': 'C&I',
      '$monthName StLgt': 'StreetLights',
    };
    if (decoder.tables.keys
        .toSet()
        .difference(tableNames.keys.toSet())
        .isNotEmpty) {
      throw StateError('Spreadsheet tab names are not as expected!');
    }

    var out = <Map<String, dynamic>>[];
    for (var tabName in decoder.tables.keys) {
      var table = decoder.tables[tabName]!;
      var data = <Map<String, dynamic>>[];
      for (var row in table.rows.skip(1)) {
        data.add({
          'code': row[0] as String,
          'supplierName': row[1] as String,
          'price': row[2] as num,
          'kWh': row[3] as num,
          'customerCount': row[4] as int,
        });
      }
      var groups = groupBy(data, (e) => e['supplierName']);
      for (var supplierName in groups.keys) {
        var xs = groups[supplierName]!;
        out.add({
          'month': month.toIso8601String(),
          'customerClass': tableNames[tabName],
          'supplierName': supplierName,
          'price': xs.map((e) => e['price']).toList(),
          'kWh': xs.map((e) => e['kWh']).toList(),
          'customerCount': xs.map((e) => e['customerCount']).toList(),
          'summary': {
            'customerCount': sum(xs.map((e) => e['customerCount'])),
            'kWh': sum(xs.map((e) => e['kWh'])),
            'volumeWeightedAveragePrice': weightedMean(
                xs.map((e) => e['price']), xs.map((e) => e['kWh'])),
          },
        });
      }
    }

    return out;
  }

  Future<int> insertData(List<Map<String, dynamic>> data) async {
    // TODO: implement processFile
    throw UnimplementedError();
  }

  /// Download an xlsx file
  Future downloadFile(Month month, Utility utility) async {
    var fileout = getFile(month, utility);
    var url = getUrl(month, utility);

    return HttpClient()
        .getUrl(url)
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));
  }

  File getFile(Month month, Utility utility) {
    return File('$dir${month.toIso8601String()}_${utility.toString()}.xlsx');
  }

  Future<List<Map<String, dynamic>>> getAllUrls() async {
    var browser = await puppeteer.launch();
    var page = await browser.newPage();

    await page.goto(
        'https://energizect.com/rate-board-residential-standard-service-generation-rates');
    var content = await page.content;
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
          var month = Month.parse(monthName, location: UTC);
          res.add({
            'month': month.toIso8601String(),
            'utility': utility,
            'url': href,
          });
        }
      }
    }

    /// sort by month and utility
    const natural = naturalComparable<String>;
    var byMonth = natural.onResultOf<Map>((Map e) => e['month']);
    var byUtility = natural.onResultOf<Map>((Map e) => e['utility']);
    var ordering = byMonth.thenCompare(byUtility);
    res.sort(ordering);
    print(json.encode(res));

    return res;
  }

  /// Missing 2019-12_Eversource on the website
  ///
  Uri getUrl(Month month, Utility utility) {
    var ut = switch (utility) {
      Utility.eversource => 'ER',
      Utility.ui => 'UR',
    };
    var mmmmyyyy = DateFormat('MMMM yyyy').format(month.start);
    var name = 'Supplier Billed Rates - $mmmmyyyy $ut.xlsx';
    String baseUrl =
        'https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/';

    if (month.year >= 2021 && month.year < 2023) {
      if (utility == Utility.eversource) {
        name = 'Supplier Billed Rates- $mmmmyyyy $ut.xlsx';
      }
    } else if (month.year >= 2023) {
      if (utility == Utility.eversource) {
        name = 'Supplier Billed Rates- $mmmmyyyy $ut.xlsx';
      }
      baseUrl = 'https://energizect.com/sites/default/files/documents/';
    }
    var url = '$baseUrl$name';

    /// check the special urls ...
    var sUrl = specialUrls.firstWhereOrNull((e) =>
        e['month'] == month.toIso8601String() &&
        e['utility'] == utility.toString());
    if (sUrl != null) {
      url = sUrl['url'] as String;
    }

    return Uri.parse(url);
  }

  /// Filename is something like '2023-03_Eversource.xlsx'
  Month getMonthFromFile(File file) {
    var x = path.basename(file.path);
    return Month.parse(x.substring(0, 7), location: UTC);
  }

  Future<void> setupDb() {
    // TODO: implement setupDb
    throw UnimplementedError();
  }
}

/// Maybe find a smarter way to do it ...
final urls = <(Month, Utility), Uri>{
  (Month.utc(2023, 2), Utility.eversource): Uri.parse(
      'https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20February%202023%20ER.xlsx'),
  (Month.utc(2023, 1), Utility.eversource): Uri.parse(
      'https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20January%202023%20ER.xlsx'),
  (Month.utc(2022, 12), Utility.eversource): Uri.parse(
      'https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20December%202022%20ER.xlsx'),
};

final specialUrls = [
  {
    "month": "2017-09",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20September%202017%20ER_0.xlsx",
  },
  //
  //
  {
    "month": "2018-02",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20February%202018%20UR_0.xlsx",
  },
  {
    "month": "2018-12",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/media/1561",
  },
  {
    "month": "2018-04",
    "utility": "Eversource",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20April%202018%20ER%20%281%29.xlsx",
  },
  //
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
  //
  {
    "month": "2021-01",
    "utility": "UI",
    "url":
        "https://energizeconn.prod.acquia-sites.com/sites/default/files/documents/Supplier%20Billed%20Rates%20-%20January%202021%20UR_0.xlsx",
  },
  //
  //
  {
    "month": "2022-04",
    "utility": "UI",
    "url":
        "https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fenergizect.com%2Fsites%2Fdefault%2Ffiles%2F2022-07%2FSupplier%2520Billed%2520Rates%2520-%2520April%25202022%2520UR.xlsx&wdOrigin=BROWSELINK",
  },
  {
    "month": "2022-05",
    "utility": "UI",
    "url": "https://energizect.com/media/5461",
  },
  {
    "month": "2022-06",
    "utility": "UI",
    "url": "https://energizect.com/media/5466",
  },
  {
    "month": "2022-07",
    "utility": "UI",
    "url": "https://energizect.com/media/5471",
  },
  {
    "month": "2022-08",
    "utility": "UI",
    "url": "https://energizect.com/media/5476",
  },
  {
    "month": "2022-09",
    "utility": "UI",
    "url": "https://energizect.com/media/5836",
  },
];

