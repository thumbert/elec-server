library db.isoexpress.da_demand_bid;

import 'dart:convert';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaDemandBidArchive extends DailyIsoExpressReport {
  DaDemandBidArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'isoexpress',
        collectionName: 'da_demand_bid');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}PricingReports/DaDemandBid/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Energy Market Demand Historical Demand Bid Report';
  }

  @override
  String getUrl(Date? asOfDate) =>
      'https://webservices.iso-ne.com/api/v1.1/hbdayaheaddemandbid/day/${yyyymmdd(asOfDate)}';
  // String getUrl(Date asOfDate) =>
  //     'https://www.iso-ne.com/static-transform/csv/histRpts/da-dmd-bid/' +
  //         'hbdayaheaddemandbid_' + yyyymmdd(asOfDate) + '.csv';

  @override
  File getFilename(Date? asOfDate) =>
      File('${dir}hbdayaheaddemandbid_${yyyymmdd(asOfDate)}.json');

  /// The CSV parser, not used anymore
  /// [rows] has the data for all the hours of the day for one location id
  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = <String, dynamic>{};

    /// daily info
    row['date'] = formatDate(rows.first['Day']);
    row['Masked Lead Participant ID'] =
        rows.first['Masked Lead Participant ID'];
    row['Masked Location ID'] = rows.first['Masked Location ID'];
    row['Location Type'] = rows.first['Location Type'];
    row['Bid Type'] = rows.first['Bid Type'];
    row['Bid ID'] = rows.first['Bid ID'];

    /// hourly info
    row['hours'] = <Map<String, dynamic>>[];
    for (var hour in rows) {
      var aux = <String, dynamic>{};
      var he = stringHourEnding(hour['Hour'])!;
      var hb = parseHourEndingStamp(hour['Day'], he);
      aux['hourBeginning'] = TZDateTime.fromMillisecondsSinceEpoch(
              location, hb.millisecondsSinceEpoch)
          .toIso8601String();

      /// add the non empty price/quantity pairs
      var pricesHour = <num?>[];
      var quantitiesHour = <num?>[];
      for (var i = 1; i <= 10; i++) {
        if (hour['Segment $i MW'] is! num) {
          break;
        }
        quantitiesHour.add(hour['Segment $i MW']);
        if (hour['Segment $i Price'] is! num) {
          break;
        }
        pricesHour.add(hour['Segment $i Price']);
      }
      // fixed demand bids have no prices
      if (pricesHour.isNotEmpty) aux['price'] = pricesHour;
      aux['quantity'] = quantitiesHour;
      row['hours'].add(aux);
    }
    return row;
  }

  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    var day = data.first['date'];
    await dbConfig.coll.remove({'date': day});
    try {
      await dbConfig.coll.insertAll(data);
    } catch (e) {
      print(' XXXX $e');
      return Future.value(1);
    }
    print('--->  SUCCESS inserting masked DA Demand Bids for $day');
    return Future.value(0);
  }

  /// New json format from web services
  @override
  List<Map<String, dynamic>> processFile(File file) {
    if (file.path.endsWith('.csv')) {
      return processCsvFile(file);
    } else if (file.path.endsWith('.json')) {
      return processJsonFile(file);
    } else {
      throw ArgumentError('File $file not supported');
    }
  }


  /// old format
  List<Map<String, dynamic>> processCsvFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    var dataByBidId = groupBy(data, (dynamic row) => row['Bid ID']);
    return dataByBidId.keys
        .map((ptid) => converter(dataByBidId[ptid]!))
        .toList();
  }

  List<Map<String, dynamic>> processJsonFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    late List<Map> xs;
    if ((aux as Map).containsKey('HbDayAheadDemandBids')) {
      if (aux['HbDayAheadDemandBids'] == '') return <Map<String, dynamic>>[];
      xs = (aux['HbDayAheadDemandBids']['HbDayAheadDemandBid'] as List)
          .cast<Map>();
    } else {
      throw StateError('File $file not in proper format');
    }

    var grouped = groupBy(xs, (Map row) => row['BidId']);

    var out = <Map<String, dynamic>>[];
    for (var xs in grouped.values) {
      // construct the hours with price quantity by segment
      var hours = [];
      for (var x in xs) {
        var quantity = <num>[];
        var price = <num>[];
        var segments = x['Segments'][0]['Segment']; // can be a Map or a List
        var xs = <Map>[];
        switch (segments) {
          case (Map segments) : xs.add(segments);
          case (List segments) : xs = [...segments];
          case _ : throw StateError('Invalid state!');
        }
        for (var segment in xs) {
          if (segment.containsKey('Price')) {
            var p = segment['Price'];
            switch (p) {
              case (String p) : price.add(num.parse(p));
              case (num p) : price.add(p);
              case _ : throw StateError('Don\'t know how to deal with $p');
            }
          }
          /// Starting in 2023-02, ISO changed the file format and the
          /// the Mw field is now quoted!
          var mw  = segment['Mw'];
          switch (mw) {
            case (String mw) : quantity.add(num.parse(mw));
            case (num mw) : quantity.add(mw);
            case _ : throw StateError('Don\'t know how to deal with $mw');
          }
        }

        hours.add({
          'hourBeginning': _reformatDateTime(x['BeginDate']),
          'quantity': quantity,
          if (price.isNotEmpty) 'price': price,
        });
      }

      var x0 = xs.first;
      if (!bidType.contains(x0['BidType'])) {
        throw StateError('Unsupported bid type: ${x0['BidType']}');
      }
      var one = <String, dynamic>{
        'date': (x0['BeginDate'] as String).substring(0, 10),
        'Masked Lead Participant ID': x0['MaskedParticipantId'] as int,
        'Masked Location ID': x0['MaskedLocationId'] as int,
        'Location Type': x0['LocationType'] as String,
        'Bid Type': x0['BidType'] as String,
        'Bid ID': x0['BidId'] as int,
        'hours': hours,
      };
      out.add(one);
    }

    return out;
  }




  @override
  Future<void> downloadDay(Date? day) async {
    var user = dotenv.env['isone_ws_user']!;
    var pwd = dotenv.env['isone_ws_password']!;

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
    await response.pipe(getFilename(day).openWrite());
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res = await dbConfig.coll.findOne({'date': date.toString()});
    if (res == null || res.isEmpty) return false;
    return true;
  }

  /// Recreate the collection from scratch.
  @override
  Future<void> setupDb() async {
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    await dbConfig.db.open();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'date': 1,
          'Bid ID': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'date': 1,
      'Masked Lead Participant ID': 1,
      'Masked Location ID': 1,
    });
    await dbConfig.db.close();
  }

  Future<void> deleteDay(Date day) async {
    await (dbConfig.coll.remove(where.eq('date', day.toString())));
  }

  /// The date time from json file is not in ISO-8601 format.
  /// For example input is: "2017-07-01T13:00:00.000-04:00",
  /// should be "2017-07-01T13:00:00.000-0400" !
  String _reformatDateTime(String input) {
    var n = input.length;
    return input.substring(0, n - 3) + input.substring(n - 2);
  }

  static const bidType = <String>{'FIXED', 'INC', 'DEC', 'PRICE'};

}
