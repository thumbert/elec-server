import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import '../lib_iso_express.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

class MonthlyAssetNcpcArchive extends IsoExpressReport {
  String getUrl(Month month) =>
      'https://webservices.iso-ne.com/api/v1.1/monthlyassetncpc/month/${month.toIso8601String().replaceAll('-', '')}';

  File getFilename(Month month) =>
      File('$dir/Raw/monthly_asset_ncpc_${month.toIso8601String()}.json');

  Future downloadMonth(Month month) async {
    var user = dotenv.env['ISONE_WS_USER']!;
    var pwd = dotenv.env['ISONE_WS_PASSWORD']!;
    await downloadUrl(getUrl(month), getFilename(month),
        username: user, password: pwd, acceptHeader: 'application/json');
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var out = <String, dynamic>{};
    for (var row in rows) {
      out['month'] = (row['BeginDate'] as String).substring(0, 7);
      out['assetId'] = row['AssetId'] as int;
      out['name'] = row['AssetName'] as String;
      out['zoneId'] = int.parse(row['Location']['@LocId']);
      out['daNcpc'] = row['DaNcpcCredit'] as num;
      out['rtNcpc'] = row['RtNcpcCredit'] as num;
    }
    return out;
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    late List<Map<String, dynamic>> xs;
    if ((aux as Map).containsKey('NCPCMonthlyAssets')) {
      if (aux['NCPCMonthlyAssets'] == '' ||
          (aux['NCPCMonthlyAssets'] as Map).isEmpty) {
        return <Map<String, dynamic>>[];
      }
      xs = (aux['NCPCMonthlyAssets']['NCPCMonthlyAsset'] as List)
          .cast<Map<String, dynamic>>();
    } else {
      throw ArgumentError(
          'Can\'t find key NCPCMonthlyAssets.  Check file $file');
    }

    return [
      // convert one row at a time
      ...xs.map((e) => converter([e]))
    ];
  }

  /// Insert data into db, one month at a time
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data to insert');
      return Future.value(-1);
    }
    var groups = groupBy(data, (dynamic e) => e['month'] as String);
    try {
      for (var month in groups.keys) {
        await dbConfig.coll.remove({'month': month});
        await dbConfig.coll.insertAll(groups[month]!);
        print('--->  Inserted DA/RT NCPC by asset for month $month');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'month': 1, 'assetId': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'assetId': 1});
    await dbConfig.db.close();
  }
}
