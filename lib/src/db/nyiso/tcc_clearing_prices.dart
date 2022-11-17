library db.nyiso.tcc_clearing_prices;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/ftr.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_nyiso_reports.dart';
import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:csv/csv.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart';
import 'package:html/parser.dart' show parse;

class NyisoTccClearingPrices extends NyisoReport {
  NyisoTccClearingPrices(
      {ComponentConfig? config, String? dir, String? outDir}) {
    Map env = Platform.environment;
    config ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'nyiso',
        collectionName: 'tcc_clearing_prices');
    dbConfig = config;
    dir ??= env['HOME']! + '/Downloads/Archive/Nyiso/TCC/ClearingPrices/Raw/';
    this.dir = dir!;
    reportName = 'NYISO TCC clearing prices';
  }

  Db get db => dbConfig.db;

  final location = getLocation('America/New_York');
  final Iso iso = Iso.newYork;

  /// Return the last auctionId downloaded on the file system or throw if
  /// no files are saved on the file system yet.
  int lastAuctionId() {
    var regex = RegExp(r'clearingprices_(\d+).csv');
    
    var files = Directory(dir)
        .listSync()
        .whereType<File>()
        .where((e) => regex.hasMatch(basename(e.path)))
        .toList();
    if (files.isEmpty) {
      throw StateError('There are no files with TTC clearing prices downloaded.\n'
          'Use archive.downloadPrices() to get some files.');
    }

    var names = files.map((e) {
      var matches = regex.allMatches(basename(e.path));
      var match = matches.elementAt(0);
      return int.parse(match.group(1) ?? '0');
    }).toList();
    names.sort();

    return names.last;
  }

  /// Download the data manually from http://tcc.nyiso.com/tcc/public/view_nodal_prices.do
  /// Each auction has an integer id, e.g. 3335 for G22-J22 auctions.
  ///
  Future<int> downloadPrices(int auctionId) async {
    // http://tcc.nyiso.com/tcc/public/view_nodal_prices.do
    var url = 'http://tcc.nyiso.com/tcc/public/view_nodal_prices_xls_view.do';

    var res = await post(Uri.parse(url), body: {
      'display': 'Y',
      'format': 'csv',
      'roundVersionId': auctionId.toString(),
    });
    // print(res.body);
    if (res.body.length < 100 || res.body.contains('improper')) {
      // this auction has not cleared yet
      return -1;
    }
    var file = File(join(dir, 'clearingprices_$auctionId.csv'));
    file.writeAsStringSync(res.body);

    return 0;
  }

  /// Only insert complete (for all ptids) auction data at a time.
  @override
  Future insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    try {
      var groups = groupBy(data, (Map e) => e['auctionName']);
      for (var group in groups.entries) {
        var auctionName = group.value.first['auctionName'] as String;
        await dbConfig.coll.remove({'auctionName': auctionName});
        await dbConfig.coll.insertAll(group.value);
        print(
            '--->  Inserted NYISO TCC clearing prices for auction $auctionName successfully');
      }
    } catch (e) {
      print('XXXX $e');
    }
  }

  /// Read the csv file and prepare it for insertion in the database.
  @override
  List<Map<String, dynamic>> processFile(File file) {
    var out = <Map<String, dynamic>>[];
    var converter = CsvToListConverter();

    var content = file.readAsStringSync();
    var xs = converter.convert(content);
    if (xs.isEmpty) return out;

    var isBopAuction = xs[3].first == 'Balance-of-Period Auction';
    if (isBopAuction) {
      /// Several auctions, first one is monthly, after that are bopp
      /// No round
      var groups = groupBy(
          xs
              .skip(10)
              .takeWhile((List e) => e[0] != '')
              .where((List e) => e.length == 9),
          (List e) => e[2]);
      var startDate = Date.parse(groups.keys.first, location: location);
      var anchorMonth =
          Month(startDate.year, startDate.month, location: location);
      var anchorMYY = formatMYY(anchorMonth);
      for (var group in groups.entries) {
        var _startDate = Date.parse(group.key, location: location);
        late String auctionName;
        late int hourCount;
        if (startDate == _startDate) {
          /// monthly auction
          auctionName = anchorMYY;
          hourCount = Term.fromInterval(anchorMonth).hours().length;
        } else {
          /// monthly bopp auction
          var _month =
              Month(_startDate.year, _startDate.month, location: location);
          var mYY = formatMYY(_month);
          auctionName = '$mYY-bopp$anchorMYY';
          hourCount = Term.fromInterval(_month).hours().length;
        }
        out.addAll(group.value.map((e) => {
              'auctionName': auctionName,
              'ptid': e[5] as int,
              'clearingPriceHour': e[8] / hourCount,
            }));
      }
      return out;
    }

    /// just one auction, has a round and one term only
    var round = int.parse((xs[4].first as String).split(' ')[1]);
    var startDate = Date.parse(xs[10][2], location: location);
    var startMonth = Month.utc(startDate.year, startDate.month);
    var endDate = Date.parse(xs[10][3], location: location);
    var term = Term(startDate, endDate);
    var hourCount = term.hours().length;
    var monthCount = xs[10][4] as int;

    // Get the month name from the official implementation
    late FtrAuction auction;
    if (monthCount == 6) {
      auction =
          SixMonthFtrAuction(iso: iso, startMonth: startMonth, round: round);
    } else if (monthCount == 12) {
      auction =
          AnnualFtrAuction(iso: iso, startMonth: startMonth, round: round);
    } else if (monthCount == 24) {
      auction =
          TwoYearFtrAuction(iso: iso, startMonth: startMonth, round: round);
    } else {
      throw StateError('Unsupported auction with number of months $monthCount');
    }

    var auctionName = auction.name;
    for (var x in xs.skip(10).where((List e) => e.length == 9)) {
      if (x[5] is int) {
        out.add({
          'auctionName': auctionName,
          'ptid': x[5] as int,
          'clearingPriceHour': x[8] / hourCount,
        });
      }
    }

    return out;
  }

  @override
  Future<void> setupDb() async {
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    await dbConfig.db.open();

    /// Create the index
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'auctionName': 1,
        },
        unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'auctionName': 1});
    await dbConfig.db.close();
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    // TODO: implement converter
    throw UnimplementedError();
  }

  /// Read the webpage to get the list of auction ids.  The list is not
  /// incrementing by one!
  Future<List<int>> getAuctionIdsPosted() async {
    var url = 'http://tcc.nyiso.com/tcc/public/view_nodal_prices.do';
    var contents = await get(Uri.parse(url));

    var document = parse(contents.body);
    var items = document.getElementsByTagName('option');
    var ids = <int>[];
    for (var item in items) {
      var value = int.tryParse(item.attributes['value'] ?? '0');
      if (value != null && value != 0) {
        ids.add(value);
      }
    }

    return ids;
  }

}
