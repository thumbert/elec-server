import 'package:html/parser.dart' show parse;


/// Results for one locality (e.g. 'NYCA', 'NYC', 'LI') in a monthly auction.
class LocalityResult {
  LocalityResult({
    required this.locality,
    required this.months,
    required this.awardedMw,
    required this.pricePerKwMonth,
  });

  /// The locality name, e.g. 'NYCA', 'NYC', 'G-J Locality', 'LI'.
  final String locality;

  /// Month labels in order, e.g. ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'].
  final List<String> months;

  /// Awarded capacity in MW for each month.
  final List<double> awardedMw;

  /// Clearing price in $/kW-Month for each month.
  final List<double> pricePerKwMonth;

  @override
  String toString() =>
      'LocalityResult($locality, awarded=$awardedMw, price=$pricePerKwMonth)';
}

/// Parsed result from the NYISO ICAP monthly auction summary page.
class MonthlyAuctionSummary {
  MonthlyAuctionSummary({
    required this.season,
    required this.auctionStarting,
    required this.postedDate,
    required this.months,
    required this.localities,
    required this.totalRosAwardedMw,
    required this.totalAwardedMw,
    required this.rosPricePaidByBidders,
  });

  /// e.g. 'Summer 2026'
  final String season;

  /// e.g. '05/2026'
  final String auctionStarting;

  /// e.g. '04/14/2026 10:00 AM'
  final String postedDate;

  /// Month labels in order, e.g. ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'].
  final List<String> months;

  /// Per-locality results, in the order they appear on the page.
  final List<LocalityResult> localities;

  /// Total ROS Awarded (MW) for each month.
  final List<double> totalRosAwardedMw;

  /// Total Awarded (MW) for each month (ROS + Locality).
  final List<double> totalAwardedMw;

  /// ROS Price Paid By Bidders (Weighted Avg.) in $/kW-Month for each month.
  final List<double> rosPricePaidByBidders;

  @override
  String toString() =>
      'MonthlyAuctionSummary($season, starting=$auctionStarting, '
      'localities=${localities.map((e) => e.locality).toList()})';
}

/// Parse the HTML response body from a POST to
/// https://icappublic.nyiso.com/ucap/public/auc_view_monthly_detail.do
///
/// Returns a [MonthlyAuctionSummary] with all clearing prices and awarded
/// quantities extracted in a type-safe manner.
///
/// Throws a [FormatException] if the expected table structure is not found.
MonthlyAuctionSummary parseMonthlyAuctionSummary(String htmlBody) {
  final document = parse(htmlBody);

  // ── Header metadata ──────────────────────────────────────────────────────
  // The <th class="inputLabel"> cell contains three lines:
  //   Season name, auction description, posted date
  final headerTh = document.querySelector('th.inputLabel');
  if (headerTh == null) {
    throw const FormatException(
        'Could not find header <th class="inputLabel">');
  }
  final headerLines = headerTh.text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (headerLines.length < 2) {
    throw FormatException('Unexpected header format. Got lines: $headerLines');
  }
  final season = headerLines[0];
  // "Monthly Auction Results for UCAP, Auction Starting 05/2026"
  final auctionStarting = _extractAuctionStarting(headerLines[1]);
  final postedDate = headerLines.length >= 3
      ? headerLines[2].replaceFirst('Posted Date:', '').trim()
      : '';

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

  // ── Column headers (month names) ─────────────────────────────────────────
  // First row: one <td> placeholder + N <th> month headers.
  final headerRow = rows[0];
  final months = headerRow
      .querySelectorAll('th')
      .map((th) => th.text.trim().replaceAll(RegExp(r'\s+'), ''))
      .where((s) => s.isNotEmpty)
      .toList();

  if (months.isEmpty) {
    throw const FormatException('No month headers found in the data table');
  }

  // ── Body rows ─────────────────────────────────────────────────────────────
  final localities = <LocalityResult>[];
  String? currentLocality;
  List<double>? currentAwarded;

  var totalRosAwardedMw = <double>[];
  var totalAwardedMw = <double>[];
  var rosPricePaidByBidders = <double>[];

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
      currentAwarded = null;
      continue;
    }

    // ── Awarded (MW) row ────────────────────────────────────────────────
    if (firstText == 'Awarded (MW)' && currentLocality != null) {
      currentAwarded = _parseDataCells(cells, months.length);
      continue;
    }

    // ── Price ($/kW - Month) row ────────────────────────────────────────
    if (firstText == 'Price (\$/kW - Month)' ||
        firstText == 'Price (\$/kW\u00a0-\u00a0Month)' ||
        firstText.startsWith('Price (')) {
      if (currentLocality != null && currentAwarded != null) {
        final prices = _parseDollarCells(cells, months.length);
        localities.add(LocalityResult(
          locality: currentLocality,
          months: List.unmodifiable(months),
          awardedMw: List.unmodifiable(currentAwarded),
          pricePerKwMonth: List.unmodifiable(prices),
        ));
        currentLocality = null;
        currentAwarded = null;
      }
      continue;
    }

    // ── Summary rows ────────────────────────────────────────────────────
    if (firstText.startsWith('Total ROS Awarded')) {
      totalRosAwardedMw = _parseDataCells(cells, months.length);
      continue;
    }
    if (firstText.startsWith('Total Awarded')) {
      totalAwardedMw = _parseDataCells(cells, months.length);
      continue;
    }
    if (firstText.startsWith('ROS Price Paid')) {
      rosPricePaidByBidders = _parseDollarCells(cells, months.length);
      continue;
    }
  }

  return MonthlyAuctionSummary(
    season: season,
    auctionStarting: auctionStarting,
    postedDate: postedDate,
    months: List.unmodifiable(months),
    localities: List.unmodifiable(localities),
    totalRosAwardedMw: List.unmodifiable(totalRosAwardedMw),
    totalAwardedMw: List.unmodifiable(totalAwardedMw),
    rosPricePaidByBidders: List.unmodifiable(rosPricePaidByBidders),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Extract '05/2026' from 'Monthly Auction Results for UCAP, Auction Starting 05/2026'
String _extractAuctionStarting(String line) {
  final match = RegExp(r'(\d{2}/\d{4})').firstMatch(line);
  return match?.group(1) ?? '';
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
