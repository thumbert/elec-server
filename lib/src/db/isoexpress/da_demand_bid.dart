library db.isoexpress.da_demand_bid;

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'dart:io';
import 'dart:async';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:logging/logging.dart';
import 'package:date/date.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart';
import '../lib_iso_express.dart';

class DemandBidSegment {
  DemandBidSegment(
      {required this.hourBeginning,
      required this.maskedParticipantId,
      required this.maskedLocationId,
      required this.locationType,
      required this.bidType,
      required this.bidId,
      required this.segment,
      required this.price,
      required this.mw});
  final TZDateTime hourBeginning;
  final int maskedParticipantId;
  final int maskedLocationId;
  final String locationType;
  final String bidType;
  final int bidId;
  final int segment;
  // price may not exist for price insensitive bids
  final num? price;
  final num mw;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hourBeginning': hourBeginning.toIso8601String(),
      'maskedParticipantId': maskedParticipantId,
      'maskedLocationId': maskedLocationId,
      'locationType': locationType,
      'bidType': bidType,
      'bidId': bidId,
      'segment': segment,
      'price': price ?? '',
      'mw': mw,
    };
  }
}

class DaDemandBidArchive {
  final reportName =
      'Day-Ahead Energy Market Demand Historical Demand Bid Report';

  late final String dir;
  late final String duckdbPath;

  static final log = Logger('DA Demand Bids');

  String getUrl(Date asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/hbdayaheaddemandbid/day/${yyyymmdd(asOfDate)}';

  final skipDays = <Date>{
    Date(2022, 5, 1, location: IsoNewEngland.location),
    Date(2022, 5, 2, location: IsoNewEngland.location),
    Date(2022, 5, 3, location: IsoNewEngland.location),
    Date(2022, 5, 4, location: IsoNewEngland.location),
    Date(2022, 5, 6, location: IsoNewEngland.location),
    Date(2022, 5, 7, location: IsoNewEngland.location),
    Date(2022, 5, 8, location: IsoNewEngland.location),
    //
    Date(2023, 1, 5, location: IsoNewEngland.location),
    Date(2023, 1, 7, location: IsoNewEngland.location),
    Date(2023, 1, 8, location: IsoNewEngland.location),
    Date(2023, 1, 9, location: IsoNewEngland.location),
    Date(2023, 1, 10, location: IsoNewEngland.location),
    Date(2023, 1, 11, location: IsoNewEngland.location),
    Date(2023, 1, 12, location: IsoNewEngland.location),
    Date(2023, 1, 15, location: IsoNewEngland.location),
    Date(2023, 1, 16, location: IsoNewEngland.location),
    Date(2023, 1, 17, location: IsoNewEngland.location),
    Date(2023, 1, 18, location: IsoNewEngland.location),
    Date(2023, 1, 19, location: IsoNewEngland.location),
    Date(2023, 1, 24, location: IsoNewEngland.location),
    Date(2023, 1, 25, location: IsoNewEngland.location),
    Date(2023, 1, 26, location: IsoNewEngland.location),
    Date(2023, 1, 28, location: IsoNewEngland.location),
    Date(2023, 1, 30, location: IsoNewEngland.location),
    Date(2023, 7, 31, location: IsoNewEngland.location),
    Date(2023, 8, 31, location: IsoNewEngland.location),
    Date(2023, 10, 31, location: IsoNewEngland.location),
    //
    Date(2024, 4, 29, location: IsoNewEngland.location),
    Date(2024, 8, 31, location: IsoNewEngland.location),
    Date(2024, 9, 3, location: IsoNewEngland.location),
  };

  File getFilename(Date asOfDate) => File(
      '$dir/Raw/${asOfDate.year}/hbdayaheaddemandbid_${yyyymmdd(asOfDate)}.json.gz');

  /// New json format from web services
  List<DemandBidSegment> processFile(File file) {
    return processFileJson(file);
  }

//   List<DemandBidSegment> getData({
//     required Connection conn,
//     required Term term,
//     required List<String> bidType,
//     List<int>? maskedParticipantId,
//     List<int>? maskedLocationId,
//   }) {
//     var query = '''
// SELECT hourBeginning, maskedParticipantId, maskedLocationId, locationType,
//     bidType, bidId, segment, price, mw
// FROM da_bids
// WHERE hour_beginning >= '${term.startDate.start.toIso8601String()}'
// AND hour_beginning < '${term.endDate.next.start.toIso8601String()}'
// AND bidType IN ('${bidType.join(',')}')
// ''';
//     print(query);
//     if (maskedParticipantId != null) {

//     }
//     if (maskedLocationId != null){

//     }
//   }

  ///
  int updateDuckDb({required List<Month> months, required String pathDbFile}) {
    final con = Connection(pathDbFile);
    con.execute('''
CREATE TABLE IF NOT EXISTS da_bids (
    hourBeginning TIMESTAMPTZ NOT NULL,
    maskedParticipantId UINTEGER NOT NULL,
    maskedAssetId UINTEGER NOT NULL,
    locationType ENUM('HUB', 'LOAD ZONE', 'NETWORK NODE', 'DRR AGGREGATION ZONE') NOT NULL,
    bidType ENUM('FIXED', 'INC', 'DEC', 'PRICE') NOT NULL,
    bidID UINTEGER NOT NULL,
    segment UTINYINT NOT NULL,
    price FLOAT,
    mw FLOAT NOT NULL,
);  
  ''');
    for (var month in months) {
      // remove the data if it's already there
      con.execute('''
DELETE FROM da_bids 
WHERE hourBeginning >= '${month.startDate}'
AND hourBeginning < '${month.next.startDate}';
      ''');
      // reinsert the data
      con.execute('''
INSERT INTO da_bids
FROM read_csv(
    '$dir/month/da_demand_bids_${month.toIso8601String()}.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
''');
      log.info('   Inserted month ${month.toIso8601String()} into DuckDb');
    }
    con.close();

    return 0;
  }

  List<DemandBidSegment> processFileJson(File file) {
    final bytes = file.readAsBytesSync();
    var content = GZipDecoder().decodeBytes(bytes);
    var data = utf8.decoder.convert(content);

    var aux = json.decode(data) as Map;
    late List<Map<String, dynamic>> xs;
    if (aux.containsKey('HbDayAheadDemandBids')) {
      if (aux['HbDayAheadDemandBids'] == '') {
        return <DemandBidSegment>[];
      }
      var bids = aux['HbDayAheadDemandBids'];
      if (bids is Map) {
        xs = (aux['HbDayAheadDemandBids']['HbDayAheadDemandBid'] as List)
            .cast<Map<String, dynamic>>();
      } else {
        xs = (aux['HbDayAheadDemandBids']['HbDayAheadDemandBid'] as List)
            .cast<Map<String, dynamic>>();
      }
    } else {
      throw StateError('File $file not in proper format');
    }

    var out = <DemandBidSegment>[];
    for (var x in xs) {
      if (!bidType.contains(x['BidType'])) {
        throw StateError('Unsupported bid type: ${x['BidType']}');
      }
      if (!locationType.contains(x['LocationType'])) {
        throw StateError('Unsupported location type: ${x['LocationType']}');
      }
      var segments = x['Segments'];
      var segment = [];
      if (segments is Map) {
        ///
        /// new format post 2023-01-01
        segment = segments['Segment'] as List;
      } else if (segments is List) {
        ///
        /// old format before 2023-01-01
        var s = segments[0]['Segment'];
        if (s is Map) {
          segment.add(segments[0]['Segment']);
        } else {
          segment = segments[0]['Segment'];
        }
      } else {
        throw StateError('Unsupported: $segments');
      }

      for (Map<String, dynamic> e in segment) {
        num? p = switch (e['Price']) {
          String price => num.parse(price),
          num price => price,
          _ => null,
        };

        num mw = switch (e['Mw']) {
          String mw => num.parse(mw),
          num mw => mw,
          _ => throw StateError('Don\'t know how to deal with ${e['Mw']}'),
        };

        int n = switch (e['Number'] ?? e['@Number']) {
          String n => int.parse(n),
          int n => n,
          _ => throw StateError(
              'Don\'t know how to parse ${e['Number'] ?? e['@Number']}'),
        };
        out.add(DemandBidSegment(
            hourBeginning: TZDateTime.parse(
                IsoNewEngland.location, _reformatDateTime(x['BeginDate'])),
            maskedParticipantId: x['MaskedParticipantId'],
            maskedLocationId: x['MaskedLocationId'],
            locationType: x['LocationType'],
            bidType: x['BidType'],
            bidId: x['BidId'],
            segment: n,
            price: p,
            mw: mw));
      }
    }

    return out;
  }

  /// Aggregate all the days of the month
  ///
  List<DemandBidSegment> aggregateDays(List<Date> days) {
    var out = <DemandBidSegment>[];
    for (var date in days) {
      if (skipDays.contains(date)) continue;
      log.info('...  Working on $date');
      final file = getFilename(date);
      if (file.existsSync()) {
        var bids = processFileJson(file);
        out.addAll(bids);
        log.info('...  Added ${bids.length} rows');
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
    final offers = aggregateDays(days);
    final file =
        File('$dir/month/da_demand_bids_${month.toIso8601String()}.csv');
    var sb = StringBuffer();
    var converter = const ListToCsvConverter();
    sb.writeln(converter.convert([offers.first.toJson().keys.toList()]));
    for (var offer in offers) {
      sb.writeln(converter.convert([offer.toJson().values.toList()]));
    }
    file.writeAsStringSync(sb.toString());

    // gzip it!
    var res = Process.runSync('gzip', ['-f', file.path], workingDirectory: dir);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(file.path)} has failed');
    }
    log.info('Gzipped file ${basename(file.path)}');

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

  /// The date time from json file is not in ISO-8601 format.
  /// For example input is: "2017-07-01T13:00:00.000-04:00",
  /// should be "2017-07-01T13:00:00.000-0400" !
  String _reformatDateTime(String input) {
    var n = input.length;
    return input.substring(0, n - 3) + input.substring(n - 2);
  }

  static const bidType = <String>{'FIXED', 'INC', 'DEC', 'PRICE'};

  static const locationType = <String>{
    'HUB',
    'LOAD ZONE',
    'NETWORK NODE',
    'DRR AGGREGATION ZONE'
  };
}
