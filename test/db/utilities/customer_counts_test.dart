library test.customer_counts;

import 'dart:io';
import 'package:elec_server/src/db/utilities/ngrid/customer_counts.dart';
import 'package:elec_server/src/db/config.dart';

import 'package:elec_server/api/utilities/api_customer_counts_ngrid.dart';

Map env = Platform.environment;

var config = ComponentConfig(
    host: '127.0.0.1', dbName: 'isone', collectionName: 'ngrid_customer_counts');

String? dir = env['HOME'] + '/Downloads/Archive/CustomerCounts/NGrid/';

updateDb() async {

  var archive = NGridCustomerCountsArchive(dbConfig: config, dir: dir);
  String url = 'https://www9.nationalgridus.com/energysupply/current/20170811/Monthly_Aggregation_customer count and usage.xlsx';
  //await archive.downloadFile(url);

//  File file = archive.getLatestFile();
//  var res = archive.readXlsx(file);
//  print(res.length);
//  res.take(20).forEach(print);

  archive.setup();
}

apiTest() async {
  var api = ApiCustomerCounts(config.db);

  await config.db.open();
  //var res = await api.apiKwhTown('Attleboro');
  //var res = await api.apiKwhZoneRateClass('SEMA', 'R1');
  var res = await api.getAvailableTowns();
  res.forEach(print);


  await config.db.close();
}


main() async {

  await updateDb();

//  await apiTest();

}