import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/nyiso.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:elec_server/client/nyiso/capacity_prices_monthly.dart';

class NyisoCapacityPricesMonthlyArchive {
  NyisoCapacityPricesMonthlyArchive(
      {required this.dir, required this.duckdbPath});

  String dir;
  String duckdbPath;

  /// Download and write CSV file.
  Future<List<Record>> downloadPricesToCsv(
      {required int seasonId, required Month month}) async {
    var url =
        'https://icappublic.nyiso.com/ucap/public/auc_view_monthly_detail.do';

    var res = await post(Uri.parse(url), body: {
      'display': 'Display',
      'seasonId': seasonId.toString(),
      'month': month.toString(DateFormat('MM/yyyy'))
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to load data: ${res.statusCode}');
    }
    final records = _parseHtml(res.body);
    if (records.isEmpty) {
      return records;
    }

    // Write CSV file
    final gzCsvFile =
        '$dir/${month.year}/capacity_prices_${month.toIso8601String()}.csv.gz';
    await Directory('$dir/${month.year}').create(recursive: true);
    final csvBuffer = StringBuffer();
    csvBuffer.writeln(
        'capability_period,auction_month,forward_month,location,clearing_price,awarded_mw');
    for (var record in records) {
      csvBuffer.writeln('${record.capabilityPeriod.name},'
          '${record.auctionMonth.toIso8601String()},'
          '${record.forwardMonth.toIso8601String()},'
          '${record.location.name},'
          '${record.clearingPrice},'
          '${record.awardedMw}');
    }
    final bytes = utf8.encode(csvBuffer.toString());
    final compressed = gzip.encode(bytes);
    await File(gzCsvFile).writeAsBytes(compressed);

    return records;
  }
}

List<Record> _parseHtml(String htmlBody) {
  final records = <Record>[];
  final document = parse(htmlBody);

  // ── Header metadata ──────────────────────────────────────────────────────
  // The <th class="inputLabel"> cell contains three lines:
  //   Season name, auction description, posted date
  final headerTh = document.querySelector('th.inputLabel');
  if (headerTh == null) {
    print(
        '------>>>  Could not find header <th class="inputLabel">.  Check page!');
    return records;
  }
  final headerLines = headerTh.text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (headerLines.length < 2) {
    throw FormatException('Unexpected header format. Got lines: $headerLines');
  }
  final capabilityPeriod = CapabilityPeriod(headerLines[0]);
  // "Monthly Auction Results for UCAP, Auction Starting 05/2026"
  final auctionMonth = _extractAuctionStarting(headerLines[1]);
  // final postedDate = DateFormat('MM/dd/yyyy hh:mm a')
  //     .parse(headerLines[2].replaceFirst('Posted Date:', '').trim());

  // ── Data table ───────────────────────────────────────────────────────────
  // There is exactly one <table width="100%"> in the page.
  final dataTable = document.querySelector('table[width="100%"]');
  if (dataTable == null) {
    throw const FormatException('Could not find <table width="100%">');
  }

  final rows = dataTable.querySelectorAll('tr');
  if (rows.isEmpty) {
    throw const FormatException('Data table has no rows');
  }

  // get the remaining months in the capability period
  final allMonths = CapabilityPeriod.containing(auctionMonth).months();
  final months = allMonths
      .where((e) => e.isAfter(auctionMonth) || e == auctionMonth)
      .toList();

  // current locality and associated data while iterating through rows
  String? currentLocality;
  List<double>? currentAwardedMw;
  List<double>? currentPrices;

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final cells = row.querySelectorAll('td, th');
    if (cells.isEmpty) continue;

    final firstCell = cells[0];
    final firstText = firstCell.text.trim();

    // Spacer rows
    if (firstText == '\u00a0' || firstText.isEmpty) continue;

    // ── Locality header row ─────────────────────────────────────────────
    // <td class="inputLabel noBorder" colspan="7">G-J Locality</td>
    final colspanAttr = firstCell.attributes['colspan'];
    if (colspanAttr != null &&
        int.tryParse(colspanAttr) == months.length + 1 &&
        cells.length == 1) {
      currentLocality = firstText;
      currentAwardedMw = null;
      continue;
    }

    // ── Awarded (MW) row ────────────────────────────────────────────────
    if (firstText == 'Awarded (MW)' && currentLocality != null) {
      currentAwardedMw = _parseDataCells(cells, months.length);
      continue;
    }

    // ── Price ($/kW - Month) row ────────────────────────────────────────
    if (firstText == 'Price (\$/kW - Month)' ||
        firstText == 'Price (\$/kW\u00a0-\u00a0Month)' ||
        firstText.startsWith('Price (')) {
      currentPrices = _parseDollarCells(cells, months.length);
    }

    if (currentLocality != null &&
        currentAwardedMw != null &&
        currentPrices != null) {
      final location = CapacityLocation.parse(currentLocality);
      for (var i = 0; i < months.length; i++) {
        records.add(Record(
          capabilityPeriod: capabilityPeriod,
          auctionMonth: auctionMonth,
          forwardMonth: months[i],
          location: location,
          clearingPrice: currentPrices[i],
          awardedMw: currentAwardedMw[i],
        ));
      }

      currentLocality = null;
      currentAwardedMw = null;
      currentPrices = null;
      continue;
    }
  }
  return records;
}

/// Extract '05/2026' from 'Monthly Auction Results for UCAP, Auction Starting 05/2026'
Month _extractAuctionStarting(String line) {
  final match = RegExp(r'(\d{2}/\d{4})').firstMatch(line);
  final dateStr = match?.group(1) ?? '';
  final parts = dateStr.split('/');
  return Month(int.parse(parts[1]), int.parse(parts[0]),
      location: NewYorkIso.location);
}

/// Parse the [count] numeric data cells (skipping the first label cell).
/// Values look like '271.7' or '1528.3'.
List<double> _parseDataCells(dynamic cells, int count) {
  final values = <double>[];
  // cells[0] is the row label; data starts at cells[1]
  for (var i = 1; i < cells.length && values.length < count; i++) {
    final text = cells[i].text.trim();
    if (text.isNotEmpty && text != '\u00a0') {
      final v = double.tryParse(text);
      if (v != null) values.add(v);
    }
  }
  return values;
}

/// Parse the [count] dollar-formatted cells (skipping the first label cell).
/// Values look like '$6.74' or '$32.00'.
List<double> _parseDollarCells(dynamic cells, int count) {
  final values = <double>[];
  for (var i = 1; i < cells.length && values.length < count; i++) {
    final text = cells[i].text.trim().replaceAll('\$', '');
    if (text.isNotEmpty && text != '\u00a0') {
      final v = double.tryParse(text);
      if (v != null) values.add(v);
    }
  }
  return values;
}
