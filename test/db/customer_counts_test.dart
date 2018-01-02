library test.customer_counts;

import 'dart:io';
import 'package:elec_server/src/db/utilities/customer_counts.dart';
import 'package:elec_server/src/db/config.dart';

import 'package:elec_server/api/api_customer_counts.dart';

Map env = Platform.environment;

ComponentConfig config = new ComponentConfig()
  ..host = '127.0.0.1'
  ..dbName = 'isone'
  ..collectionName = 'ngrid_customer_counts'
  ..DIR = env['HOME'] + '/Downloads/Archive/CustomerCounts/NGrid/';

updateDb() async {

  var archive = new NGridCustomerCountsArchive();
  String url = 'https://www9.nationalgridus.com/energysupply/current/20170811/Monthly_Aggregation_customer count and usage.xlsx';
  //await archive.downloadFile(url);

//  File file = archive.getLatestFile();
//  var res = archive.readXlsx(file);
//  print(res.length);
//  res.take(20).forEach(print);

  archive.setup();
}

apiTest() async {
  var api = new ApiCustomerCounts(config.db);

  await config.db.open();
  //var res = await api.apiKwhTown('Attleboro');
  //var res = await api.apiKwhZoneRateClass('SEMA', 'R1');
  var res = await api.getAvailableTowns();
  res.forEach(print);


  await config.db.close();
}


main() async {

//  await updateDb();

  await apiTest();
}