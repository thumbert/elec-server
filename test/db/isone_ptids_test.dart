library test.db.isone_ptids_test;


import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';

import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/isone_ptids.dart';
import 'package:elec_server/api/api_isone_ptids.dart';

Map env = Platform.environment;

ComponentConfig config = new ComponentConfig()
  ..host = '127.0.0.1'
  ..dbName = 'isone'
  ..collectionName = 'pnode_table'
  ..DIR = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';

downloadFile() async {
  var archive = new PtidArchive(config: config);
  String url =
      'https://www.iso-ne.com/static-assets/documents/2017/08/pnode_table_2017_08_03.xls';
  archive.downloadFile(url);
}


ingestionTest() async {
  var archive = new PtidArchive(config: config);
  await archive.setup();

//  File file = new File(config.DIR + 'pnode_table_2017_09_19.xlsx');
//  print(archive.readXlsx(file));
//  await archive.db.open();
//  await archive.insertMongo(file);
//  await archive.db.close();

}

apiTest() async {
  var api = new ApiPtids(config.db);
  print(await api.getAvailableAsOfDates());
  print(await api.apiPtidTableAsOfDate('2017-10-01'));
}


main() async {
  ingestionTest();

//  await config.db.open();
//  await apiTest();
//  await config.db.close();
}

