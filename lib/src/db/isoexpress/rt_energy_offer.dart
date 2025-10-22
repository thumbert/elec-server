import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/client/isoexpress/energy_offer.dart';
import 'package:logging/logging.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import '../lib_iso_express.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class RtEnergyOfferArchive {
  RtEnergyOfferArchive({required this.dir});

  final String dir;
  static final log = Logger('RT Energy Offers');
  static final reportName = 'Real-Time Energy Market Historical Offer Report';

  /// ISO has not published data for these days
  static final missingDays = <Date>{};

  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/hbrealtimeenergyoffer/day/${yyyymmdd(asOfDate)}';

  File getFilename(Date asOfDate) => File(
      '$dir/Raw/${asOfDate.year}/hbrealtimeenergyoffer_${yyyymmdd(asOfDate)}.json.gz');

  List<EnergyOfferSegment> processFile(File file,
      {String extension = '.json'}) {
    return _processFileJson(file);
  }

  List<EnergyOfferSegment> _processFileJson(File file) {
    final bytes = file.readAsBytesSync();
    var content = GZipDecoder().decodeBytes(bytes);
    var aux = utf8.decoder.convert(content);
    var data = json.decode(aux) as Map<String, dynamic>;

    var out = <EnergyOfferSegment>[];
    if (data['HbRealTimeEnergyOffers'] == '') return out;

    late List<Map<String, dynamic>> xs;

    final offers = data['HbRealTimeEnergyOffers'];
    if (offers is Map) {
      xs = (data['HbRealTimeEnergyOffers']['HbRealTimeEnergyOffer'] as List)
          .cast<Map<String, dynamic>>();
    } else {
      throw StateError('Unsupported format');
    }

    for (Map<String, dynamic> x in xs) {
      out.addAll(EnergyOfferSegment.fromJson(x));
    }

    return out;
  }

  /// File is in the long format, ready to upload into DuckDb
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
        File('$dir/month/rt_energy_offers_${month.toIso8601String()}.csv');
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
CREATE TABLE IF NOT EXISTS rt_offers (
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
DELETE FROM rt_offers 
WHERE HourBeginning >= '${month.startDate}'
AND HourBeginning < '${month.next.startDate}';
      ''');
      // reinsert the data
      con.execute('''
INSERT INTO rt_offers
FROM read_csv(
    '$dir/month/rt_energy_offers_${month.toIso8601String()}.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
''');
      log.info('   Inserted month ${month.toIso8601String()} into DuckDb');
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
}
