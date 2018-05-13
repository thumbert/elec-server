library db.customer_counts;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';

Map customerCountsUrl = {
  new Month(2018,2): '/content/docs/default-source/default-document-library/customer-count-report---february-20189d8aa40f1b5267e39dbdff3500e2e88e.xlsx?sfvrsn=71d8c362_0',
  new Month(2018,1): '/content/docs/default-source/default-document-library/customer-count-report---january-20187c8aa40f1b5267e39dbdff3500e2e88e.xlsx?sfvrsn=92d8c362_0',
  new Month(2017,12): '/content/docs/default-source/default-document-library/customer-count-report---december-2017428aa40f1b5267e39dbdff3500e2e88e.xlsx?sfvrsn=d8d8c362_0',
  new Month(2017,11): '/content/docs/default-source/ct---pdfs/customer-count-report---november-2017.xlsx?sfvrsn=6506c462_0',
  new Month(2017,10): '/content/docs/default-source/ct---pdfs/customer-count-report---october-2017.xlsx?sfvrsn=9406c462_0',
  new Month(2017,9): '/content/docs/default-source/ct---pdfs/customer-count-report----september-2017.xlsx?sfvrsn=bb06c462_0',
  new Month(2017,8): '/content/docs/default-source/ct---pdfs/2017-08.xlsx?sfvrsn=7f59c762_2',
  new Month(2017,7): '/content/docs/default-source/ct---pdfs/2017-07.xlsx?sfvrsn=7859c762_2',
  new Month(2017,6): '/content/docs/default-source/ct---pdfs/2017-06.xlsx?sfvrsn=7959c762_2',
  new Month(2017,5): '/content/docs/default-source/ct---pdfs/2017-05.xlsx?sfvrsn=d6a6fb62_2',
  new Month(2017,4): '/content/docs/default-source/ct---pdfs/2017-04.xlsx?sfvrsn=77a6fb62_2',
  new Month(2017,3): '/content/docs/default-source/ct---pdfs/2017-03.xlsx?sfvrsn=70a6fb62_2',
  new Month(2017,2): '/content/docs/default-source/ct---pdfs/2017-02.xlsx?sfvrsn=fa35fc62_2',
  new Month(2017,1): '/content/docs/default-source/ct---pdfs/2017-01.xlsx?sfvrsn=fb35fc62_2',
  new Month(2016,12): '/content/docs/default-source/ct---pdfs/2016-12-(2).xlsx?sfvrsn=9d35fc62_2',
  new Month(2016,11): '/content/docs/default-source/ct---pdfs/2016-11.xlsx?sfvrsn=3f88fe62_2',
  new Month(2016,10): '/content/docs/default-source/ct---pdfs/2016-10.xlsx?sfvrsn=f88fe62_2',
  new Month(2016,9): '/content/docs/default-source/ct---pdfs/2016-09.xlsx?sfvrsn=1f88fe62_2',
  new Month(2016,8): '/content/docs/default-source/ct---pdfs/2016-08.xlsx?sfvrsn=78fcff62_2',
  new Month(2016,7): '/content/docs/default-source/ct---pdfs/2016-07.xlsx?sfvrsn=76fcff62_2',
  new Month(2016,6): '/content/docs/default-source/ct---pdfs/2016-06.xlsx?sfvrsn=6cfcff62_2',
  new Month(2016,5): '/content/docs/default-source/ct---pdfs/2016-05.xlsx?sfvrsn=c7ebf062_0',
  new Month(2016,4): '/content/docs/default-source/ct---pdfs/2016-04.xlsx?sfvrsn=f3ebf062_0',
  new Month(2016,3): '/content/docs/default-source/ct---pdfs/2016-03.xlsx?sfvrsn=efebf062_0',
  new Month(2016,2): '/content/docs/default-source/ct---pdfs/2016-02.xlsx?sfvrsn=c61af362_0',
  new Month(2016,1): '/content/docs/default-source/ct---pdfs/2016-01.xlsx?sfvrsn=f21af362_0',
  new Month(2015,12): '/content/docs/default-source/ct---pdfs/2015-12.xlsx?sfvrsn=ee1af362_0',
  new Month(2015,11): '/content/docs/default-source/ct---pdfs/2015-11.xlsx?sfvrsn=bfccf562_0',
  new Month(2015,10): '/content/docs/default-source/ct---pdfs/2015-10.xlsx?sfvrsn=83ccf562_0',
  new Month(2015,9): '/content/docs/default-source/ct---pdfs/2015-09.xlsx?sfvrsn=97ccf562_0',
  new Month(2015,8): '/content/docs/default-source/ct---pdfs/2015-08.xlsx?sfvrsn=3bc0f662_0',
  new Month(2015,7): '/content/docs/default-source/ct---pdfs/2015-07.xlsx?sfvrsn=37c0f662_0',
  new Month(2015,6): '/content/docs/default-source/ct---pdfs/2015-06.xlsx?sfvrsn=23c0f662_0',
  new Month(2015,5): '/content/docs/default-source/ct---pdfs/2015-05.xlsx?sfvrsn=f994e862_0',
  new Month(2015,4): '/content/docs/default-source/ct---pdfs/2015-04.xlsx?sfvrsn=f594e862_0',
  new Month(2015,3): '/content/docs/default-source/ct---pdfs/2015-03.xlsx?sfvrsn=e194e862_0',
  new Month(2015,2): '/content/docs/default-source/ct---pdfs/2015-02.xlsx?sfvrsn=1d97e862_0',
  new Month(2015,1): '/content/docs/default-source/ct---pdfs/2015-01.xlsx?sfvrsn=4f0aeb62_0',
  new Month(2014,12): '/content/docs/default-source/ct---pdfs/2014-12.xlsx?sfvrsn=aecbec62_0',
  new Month(2014,11): '/content/docs/default-source/ct---pdfs/2014-11.xlsx?sfvrsn=6168ec62_2',
  new Month(2014,10): '/content/docs/default-source/wma---pdfs/2014-10.xlsx?sfvrsn=7568ec62_0',
  new Month(2014,9): '/content/docs/default-source/ct---pdfs/2014-09.xlsx?sfvrsn=7968ec62_0',
  new Month(2014,8): '/content/docs/default-source/ct---pdfs/2014-08.xlsx?sfvrsn=4d68ec62_0',
  new Month(2014,7): '/content/docs/default-source/ct---pdfs/2014-07.xlsx?sfvrsn=5168ec62_0',
  new Month(2014,6): '/content/docs/default-source/ct---pdfs/2014-06.xlsx?sfvrsn=2568ec62_0',
  new Month(2014,5): '/content/docs/default-source/ct---pdfs/2014-05.xlsx?sfvrsn=2968ec62_0',
  new Month(2014,4): '/content/docs/default-source/ct---pdfs/2014-04.xlsx?sfvrsn=3d68ec62_0',
  new Month(2014,3): '/content/docs/default-source/ct---pdfs/2014-03.xlsx?sfvrsn=168ec62_0',
  new Month(2014,2): '/content/docs/default-source/ct---pdfs/2014-02.xlsx?sfvrsn=1568ec62_0',
  new Month(2014,1): '/content/docs/default-source/ct---pdfs/2014-01.xlsx?sfvrsn=1968ec62_0',
};


class EversourceCtCustomerCountsArchive {
  ComponentConfig dbConfig;
  SpreadsheetDecoder _decoder;
  String dir;

  EversourceCtCustomerCountsArchive({this.dbConfig, this.dir}) {
    Map env = Platform.environment;
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'eversource'
        ..collectionName = 'customer_counts_ct';
    }
    if (dir == null)
      dir = env['HOME'] + '/Downloads/Archive/CustomerCounts/Eversource/CT/';
    if (!new Directory(dir).existsSync())
      new Directory(dir).createSync(recursive: true);
  }

  Db get db => dbConfig.db;

  /// insert data from one or multiple files
  Future insertData(List<Map> data) {
    return dbConfig.coll
        .insertAll(data)
        .then((_) => print('--->  SUCCESS'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /// Read the entire contents of a given spreadsheet, and prepare it for
  /// Mongo insertion.
  List<Map> readXlsx(File file) {
    var bytes = file.readAsBytesSync();
    _decoder = new SpreadsheetDecoder.decodeBytes(bytes);

    var table = _decoder.tables['Smry Load Customer'];
    List<Map> res = [
      {'provider': 'competitive supply', 'service': 'residential ss',
        'mwh': table.rows[10][1], 'customer counts': table.rows[21][1]},
      {'provider': 'utility', 'service': 'residential ss',
        'mwh': table.rows[11][1], 'customer counts': table.rows[22][1]},

      {'provider': 'competitive supply', 'service': 'business ss',
        'mwh': table.rows[10][3], 'customer counts': table.rows[21][3]},
      {'provider': 'utility', 'service': 'business ss',
        'mwh': table.rows[11][3], 'customer counts': table.rows[22][3]},

      {'provider': 'competitive supply', 'service': 'business lrs',
        'mwh': table.rows[10][5], 'customer counts': table.rows[21][5]},
      {'provider': 'utility', 'service': 'business lrs',
        'mwh': table.rows[11][5], 'customer counts': table.rows[22][5]},
    ];

    /// add the month too
    String month = path.basename(file.path).substring(0,7);
    res = res.map((Map e) {
      return {'month': month}..addAll(e);
    }).toList();

    return res;
  }

  /// Get the file for this month
  File getFile(Month month) {
    return new File(dir + '${month.startDate.toString().substring(0, 7)}.xlsx');
  }

  /// Download a file.
  /// https://www.eversource.com/content/ct-c/about/about-us/doing-business-with-us/energy-supplier-information/wholesale-supply-(connecticut)
  Future downloadFile(Month month) async {
    File fileout = new File(dir + month.startDate.toString().substring(0,7) + '.xlsx');
    print(fileout);

    if (fileout.existsSync()) {
      print("Month $month is already downloaded.");
      return new Future.value(null);
    }

    String url = 'https://www.eversource.com' + customerCountsUrl[month];
    if (url == null)
      throw new ArgumentError('Month $month is not in the url Map');

    return new HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
        response.pipe(fileout.openWrite()));
  }

  Future<Null> setup() async {
    if (!new Directory(dir).existsSync())
      new Directory(dir).createSync(recursive: true);

    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    print('Collections in ${dbConfig.dbName} db:');
    print(collections);
    if (collections.contains(dbConfig.collectionName)) await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'month': 1, 'provider': 1, 'service': 1}, unique: true);

    await dbConfig.db.close();
  }
}
