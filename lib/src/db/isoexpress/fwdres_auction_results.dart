library db.isoexpress.fwdres_auction_results;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';

class FwdResAuctionResultsArchive extends IsoExpressReport {
  FwdResAuctionResultsArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'isoexpress',
        collectionName: 'fwdres_auction_results');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}FwdRes/AuctionResults/Raw/';
    this.dir = dir;
    reportName = 'Forward Reserve Auction Results Report';
  }

  /// [auctionName] is in format 'Summer 20', or 'Winter 20-21'
  ///https://www.iso-ne.com/static-assets/documents/2022/04/fr_auction_summer_2022.csv
  String getUrl(String auctionName) {
    if (!urls.containsKey(auctionName)) {
      throw ArgumentError(
          'Url does not yet exist for this auction!  Update map.');
    }
    return urls[auctionName]!;
  }

  File getFilename(String auctionName) {
    return File('${dir}fwdres_auction_results_${startMonth(auctionName).toIso8601String()}.csv');
  }

  /// Can insert data for multiple auctions at once
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    var groups = groupBy(data, (Map e) => e['auctionName'] as String);
    for (var auctionName in groups.keys) {
      await dbConfig.coll.remove({'auctionName': auctionName});
      try {
        await dbConfig.coll.insertAll(groups[auctionName]!);
      } catch (e) {
        print(' XXXX $e');
        return Future.value(1);
      }
      print('--->  SUCCESS inserting $reportName for $auctionName');
    }
    return Future.value(0);
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];

    var out = <Map<String, dynamic>>[];
    for (var row in data) {
      // each row creates 2 documents, one for TMOR and one for TMNSR
      var yyyymm = (row['Forward Reserve Procurement Period'] as String)
          .split(' ')[1]
          .substring(0, 7)
          .split('/');
      var startMonth = Month.utc(int.parse(yyyymm[1]), int.parse(yyyymm[0]));
      out.add({
        'auctionName': auctionName(startMonth),
        'reserveZoneId': row['Reserve Zone ID'] as int,
        'reserveZoneName': row['Reserve Zone Name'] as String,
        'product': 'TMNSR',
        'mwOffered': row['Forward TMNSR Total Supply Offered (MW)'] as num,
        'mwCleared': row['Forward TMNSR Supply Cleared (MW)'] as num,
        'clearingPrice':
            row['Forward TMNSR Clearing Price (\$MW-Month)'] as num,
        'proxyPrice': row['System TMNSR Proxy Price (\$MW-Month)'] as num,
      });
      out.add({
        'auctionName': auctionName(startMonth),
        'reserveZoneId': row['Reserve Zone ID'] as int,
        'reserveZoneName': row['Reserve Zone Name'] as String,
        'product': 'TMOR',
        'mwOffered': row['Forward TMOR Total Supply Offered (MW)'] as num,
        'mwCleared': row['Forward TMOR Supply Cleared (MW)'] as num,
        'clearingPrice': row['Forward TMOR Clearing Price (\$MW-Month)'] as num,
        'proxyPrice': row['System TMOR Proxy Price (\$MW-Month)'] as num,
      });
    }
    return out;
  }

  @override
  setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'auctionName': 1});
    await dbConfig.db.close();
  }

  /// Return the starting month of the auction.
  /// [auctionName] is in format 'Summer 20', or 'Winter 20-21'
  Month startMonth(String auctionName) {
    late int month;
    late int year;
    if (auctionName.startsWith('Summer')) {
      month = 6;
      year = 2000 +
          int.parse(auctionName.replaceAll('Summer ', '').substring(0, 2));
    } else if (auctionName.startsWith('Winter')) {
      month = 10;
      year = 2000 +
          int.parse(auctionName.replaceAll('Winter ', '').substring(0, 2));
    } else {
      throw ArgumentError('Wrong auctionName $auctionName');
    }
    return Month.utc(year, month);
  }

  String auctionName(Month startMonth) {
    var yy = (startMonth.year - 2000).toString().padLeft(2, '0');
    if (startMonth.month == 6) {
      return 'Summer $yy';
    } else if (startMonth.month == 10) {
      var yy1 = (startMonth.year - 2000 + 1).toString().padLeft(2, '0');
      return 'Winter $yy-$yy1';
    } else {
      throw StateError('Wrong start month $startMonth');
    }
  }

  /// The ISO is clearly not very consistent with the naming conventions
  final urls = <String, String>{
    'Summer 23':
        'https://www.iso-ne.com/static-assets/documents/2023/04/forward_reserve_auction_results_2023.csv',
    'Summer 22':
        'https://www.iso-ne.com/static-assets/documents/2022/04/fr_auction_summer_2022.csv',
    'Summer 21':
        'https://www.iso-ne.com/static-assets/documents/2021/04/fr_auction_summer2021.csv',
    'Summer 20':
        'https://www.iso-ne.com/static-assets/documents/2020/04/forward_reserve_auction_results.csv',
    'Summer 19':
        'https://www.iso-ne.com/static-assets/documents/2019/04/fr_auction_sum2019.csv',
    'Summer 18':
        'https://www.iso-ne.com/static-assets/documents/2018/04/fr_auction_sum2018.csv',
    'Summer 17':
        'https://www.iso-ne.com/static-assets/documents/2017/04/fr_auction_sum2017.csv',
    'Summer 16':
        'https://www.iso-ne.com/static-assets/documents/2016/04/fr_auction_sum2016.csv',
    'Winter 23-24':
        'https://www.iso-ne.com/static-assets/documents/2023/08/forward_reserve_auction_results.csv',
    'Winter 22-23':
        'https://www.iso-ne.com/static-assets/documents/2022/08/forward_reserve_auction_results.csv',
    'Winter 21-22':
        'https://www.iso-ne.com/static-assets/documents/2021/08/fr_auction_winter2021-22.csv',
    'Winter 20-21':
        'https://www.iso-ne.com/static-assets/documents/2020/08/fr_auction_win2020-21.csv',
    'Winter 19-20':
        'https://www.iso-ne.com/static-assets/documents/2019/08/fr_auction_winter2019-20.csv',
    'Winter 18-19':
        'https://www.iso-ne.com/static-assets/documents/2018/08/fr_auction_winter2018-19.csv',
    'Winter 17-18':
        'https://www.iso-ne.com/static-assets/documents/2017/08/fr_auction_win2017-18.csv',
    'Winter 16-17':
        'https://www.iso-ne.com/static-assets/documents/2016/08/forward_reserve_auction_results.csv'
  };

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    // TODO: implement converter
    throw UnimplementedError();
  }
}
