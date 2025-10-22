import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/client/isoexpress/energy_offer.dart';
import 'package:logging/logging.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import '../lib_iso_express.dart';

class DaEnergyOfferArchive {
  DaEnergyOfferArchive({required this.dir, required this.duckDbPath});

  final String dir;
  final String duckDbPath;
  static final log = Logger('DA Energy Offers');
  static final reportName = 'Day-Ahead Energy Market Historical Offer Report';

  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/hbdayaheadenergyoffer/day/${yyyymmdd(asOfDate)}';

  File getFilename(Date asOfDate) => File(
      '$dir/Raw/${asOfDate.year}/hbdayaheadenergyoffer_${yyyymmdd(asOfDate)}.json.gz');

  List<EnergyOfferSegment> processFile(File file) {
    return _processFileJson(file);
  }

  List<EnergyOfferSegment> _processFileJson(File file) {
    final bytes = file.readAsBytesSync();
    var content = GZipDecoder().decodeBytes(bytes);
    var aux = utf8.decoder.convert(content);
    var data = json.decode(aux) as Map<String, dynamic>;

    var out = <EnergyOfferSegment>[];
    if (data['HbDayAheadEnergyOffers'] == '') return out;

    late List<Map<String, dynamic>> xs;

    final offers = data['HbDayAheadEnergyOffers'];
    if (offers is Map) {
      xs = (data['HbDayAheadEnergyOffers']['HbDayAheadEnergyOffer'] as List)
          .cast<Map<String, dynamic>>();
    } else {
      throw StateError('Unsupported format');
    }

    for (Map<String, dynamic> x in xs) {
      out.addAll(EnergyOfferSegment.fromJson(x));
    }
    return out;
  }

  /// Aggregate all the days of the month in
  ///
  List<EnergyOfferSegment> aggregateDays(List<Date> days) {
    var out = <EnergyOfferSegment>[];
    for (var date in days) {
      log.info('...  Working on $date');
      final file = getFilename(date);
      if (file.existsSync()) {
        var content = GZipDecoder().decodeBytes(file.readAsBytesSync());
        var aux = utf8.decoder.convert(content);
        var rows = const CsvToListConverter(eol: '\n').convert(aux);
        var offers = rows
            .where((row) => row.first == 'D')
            .expand((row) => EnergyOfferSegment.fromRow(row));
        out.addAll(offers);
        log.info('...  Added ${rows.length} rows');
      } else {
        throw StateError('Missing file for $date');
      }
    }
    log.info('aggregated data has ${out.length} rows!');
    return out;
  }

  /// File is in the long format, ready for duckdb to upload
  ///
  int makeGzFileForMonth(Month month) {
    var days = month.days();
    var converter = const ListToCsvConverter();

    var sb = StringBuffer();
    for (final day in days) {
      log.info('Working on day $day');
      var file = getFilename(day);
      var offers = processFile(file);
      if (offers.isEmpty) {
        log.info('--------->  EMPTY json file for $day');
      }
      if (offers.isEmpty) continue;
      if (day == days.first) {
        sb.writeln(converter.convert([offers.first.toJson().keys.toList()]));
      }
      for (final offer in offers) {
        sb.writeln(converter.convert([offer.toJson().values.toList()]));
      }
    }
    final file =
        File('$dir/month/da_energy_offers_${month.toIso8601String()}.csv');
    file.writeAsStringSync(sb.toString());

    // gzip it!
    var res = Process.runSync('gzip', ['-f', file.path], workingDirectory: dir);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(file.path)} has failed');
    }
    log.info('Gzipped file ${basename(file.path)}');

    return 0;
  }

  ///
  int updateDuckDb({required List<Month> months, required String pathDbFile}) {
    final con = Connection(pathDbFile);
    con.execute('''
CREATE TABLE IF NOT EXISTS da_offers (
    HourBeginning TIMESTAMPTZ NOT NULL,
    MaskedParticipantId UINTEGER NOT NULL,
    MaskedAssetId UINTEGER NOT NULL,
    MustTakeEnergy FLOAT NOT NULL,
    MaxDailyEnergyAvailable FLOAT NOT NULL,
    EcoMax FLOAT NOT NULL,
    EcoMin FLOAT NOT NULL,
    ColdStartupPrice FLOAT NOT NULL,
    IntermediateStartupPrice FLOAT NOT NULL,
    HotStartupPrice FLOAT NOT NULL,
    NoLoadPrice FLOAT NOT NULL,
    Segment UTINYINT NOT NULL,
    Price FLOAT NOT NULL,
    Quantity FLOAT NOT NULL,
    Claim10 FLOAT NOT NULL,
    Claim30 FLOAT NOT NULL,
    UnitStatus ENUM('ECONOMIC', 'UNAVAILABLE', 'MUST_RUN') NOT NULL,
);  
  ''');
    for (var month in months) {
      // remove the data if it's already there
      con.execute('''
DELETE FROM da_offers 
WHERE HourBeginning >= '${month.startDate}'
AND HourBeginning < '${month.next.startDate}';
      ''');
      // reinsert the data
      con.execute('''
INSERT INTO da_offers
FROM read_csv(
    '$dir/month/da_energy_offers_${month.toIso8601String()}.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
''');
      log.info('   Inserted month ${month.toIso8601String()} into DuckDB');
    }
    con.close();

    return 0;
  }

  Future<void> downloadDay(Date day) async {
    var user = dotenv.env['ISONE_WS_USER']!;
    var pwd = dotenv.env['ISONE_WS_PASSWORD']!;

    var client = HttpClient()
      ..addCredentials(
          Uri.parse(getUrl(day)), '', HttpClientBasicCredentials(user, pwd))
      ..userAgent = 'Mozilla/4.0'
      ..badCertificateCallback = (cert, host, port) {
        print('Bad certificate connecting to $host:$port:');
        return true;
      };
    var request = await client.getUrl(Uri.parse(getUrl(day)));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    var response = await request.close();
    var fileName = getFilename(day).path.removeSuffix('.gz');
    if (!Directory(dirname(fileName)).existsSync()) {
      Directory(dirname(fileName)).createSync(recursive: true);
    }
    await response.pipe(File(fileName).openWrite());
    // gzip it
    var res = Process.runSync('gzip', ['-f', fileName], workingDirectory: dir);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(fileName)} has failed');
    }
    log.info('Downloaded and gzipped file ${basename(fileName)}');
  }

  /// Get data from DuckDB directly.
  /// Correct the offer price for must run units.
  List<Datum> getOffers(Connection conn, TZDateTime hourBeginning) {
    final query = '''
SELECT 
    MaskedAssetId,
    UnitStatus,
    Segment,
    CASE 
        WHEN CumQty - EcoMin < 5 AND UnitStatus = 'MUST_RUN' THEN -999
        ELSE Price
    END AS AdjustedPrice,
    Quantity
FROM (
    SELECT 
        MaskedAssetId, 
        UnitStatus, 
        EcoMin, 
        Segment, 
        Price, 
        Quantity,
        SUM(Quantity) OVER (
            PARTITION BY MaskedAssetId 
            ORDER BY Segment 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumQty
    FROM da_offers
    WHERE HourBeginning = '${hourBeginning.toIso8601String()}'
);
    ''';
    // print(query);
    final data = conn.fetchRows(
        query,
        (List row) => Datum(
              hourBeginning: hourBeginning,
              maskedAssetId: row[0] as int,
              unitStatus: UnitStatus.parse(row[1] as String),
              segment: row[2] as int,
              price: row[3] as num,
              quantity: row[4] as num,
            ));
    return data;
  }
}
