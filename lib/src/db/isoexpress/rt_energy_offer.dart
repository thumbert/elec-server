library db.isoexpress.rt_energy_offer;

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/isoexpress/energy_offer.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class RtEnergyOfferArchive {
  RtEnergyOfferArchive({required this.dir});

  final String dir;
  static final log = Logger('RT Energy Offers');
  static final reportName = 'Real-Time Energy Market Historical Offer Report';

  /// ISO has not published data for these days
  static final missingDays = <Date>{};

  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/hbrealtimeenergyoffer/day/${yyyymmdd(asOfDate)}';

  File getFilename(Date asOfDate) =>
      File('$dir/Raw/hbrealtimeenergyoffer_${yyyymmdd(asOfDate)}.json');

  /// [rows] has the data for all the hours of the day for one asset
  Map<String, dynamic> converter(List<Map> rows) {
    var row = <String, dynamic>{};

    /// daily info
    row['date'] = formatDate(rows.first['Day']);
    row['Masked Lead Participant ID'] =
        rows.first['Masked Lead Participant ID'];
    row['Masked Asset ID'] = rows.first['Masked Asset ID'];
    row['Must Take Energy'] = rows.first['Must Take Energy'];
    row['Maximum Daily Energy Available'] =
        rows.first['Maximum Daily Energy Available'];
    row['Unit Status'] = rows.first['Unit Status'];
    row['Claim 10'] = rows.first['Claim 10'];
    row['Claim 30'] = rows.first['Claim 30'];

    /// hourly info
    row['hours'] = [];
    for (var hour in rows) {
      var aux = <String, dynamic>{};
      var utc = parseHourEndingStamp(hour['Day'], hour['Trading Interval']);
      aux['hourBeginning'] = TZDateTime.fromMicrosecondsSinceEpoch(
              IsoNewEngland.location, utc.microsecondsSinceEpoch)
          .toIso8601String();
      aux['Economic Maximum'] = hour['Economic Maximum'];
      aux['Economic Minimum'] = hour['Economic Minimum'];
      aux['Cold Startup Price'] = hour['Cold Startup Price'];
      aux['Intermediate Startup Price'] = hour['Intermediate Startup Price'];
      aux['Hot Startup Price'] = hour['Hot Startup Price'];
      aux['No Load Price'] = hour['No Load Price'];

      /// add the non empty price/quantity pairs
      var pricesHour = <num?>[];
      var quantitiesHour = <num?>[];
      for (var i = 1; i <= 10; i++) {
        if (hour['Segment $i Price'] is! num) break;
        pricesHour.add(hour['Segment $i Price']);
        quantitiesHour.add(hour['Segment $i MW']);
      }
      aux['price'] = pricesHour;
      aux['quantity'] = quantitiesHour;
      row['hours'].add(aux);
    }
    return row;
  }

  List<EnergyOfferSegment> processFile(File file,
      {String extension = '.json'}) {
    if (extension == '.csv') {
      return _processFileCsv(file);
    } else if (extension == '.json') {
      return _processFileJson(file);
    } else {
      throw ArgumentError('File type $extension not supported');
    }
  }

  List<EnergyOfferSegment> _processFileJson(File file) {
    final aux = file.readAsStringSync();
    final data = json.decode(aux) as Map<String, dynamic>;
    var out = <EnergyOfferSegment>[];
    if (data['HbRealTimeEnergyOffers'] == '') return out;

    final offers =
        data['HbRealTimeEnergyOffers']['HbRealTimeEnergyOffer'] as List;
    for (Map<String, dynamic> offer in offers) {
      out.addAll(EnergyOfferSegment.fromJson(offer));
    }

    return out;
  }

  List<EnergyOfferSegment> _processFileCsv(File file) {
    // var data = mis.readReportTabAsMap(file, tab: 0);
    // if (data.isEmpty) return [];
    // var dataByAssetId = groupBy(data, (dynamic row) => row['Masked Asset ID']);
    // var out = dataByAssetId.keys
    //     .map((ptid) => converter(dataByAssetId[ptid]!))
    //     .toList();
    return <EnergyOfferSegment>[];
  }

  /// Aggregate all the days of the month in
  ///
  List<EnergyOfferSegment> aggregateDays(List<Date> days) {
    var out = <EnergyOfferSegment>[];
    for (var date in days) {
      log.info('...  Working on $date');
      final file = getFilename(date);
      if (file.existsSync()) {
        var rows = file
            .readAsLinesSync()
            .map((e) => const CsvToListConverter().convert(e).first);
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
  int updateDuckDb([List<Month>? months]) {
    final home = Platform.environment['HOME'];
    final con =
        Connection('$home/Downloads/Archive/IsoExpress/energy_offers.duckdb');
    con.execute('''
CREATE TABLE IF NOT EXISTS rt_energy_offers (
    HourBeginning TIMESTAMP_S NOT NULL,
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
    if (months != null) {
      /// TODO!
    } else {
      con.execute('''
INSERT INTO rt_energy_offers
FROM read_csv(
    '$dir/month/rt_energy_offers_*.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
''');
    }
    con.close();

    return 0;
  }
}
