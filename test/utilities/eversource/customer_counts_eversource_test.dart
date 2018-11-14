library test.utilities.eversource.customer_counts;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec_server/src/db/utilities/eversource/customer_counts_ct.dart';
import 'package:elec_server/src/db/config.dart';

import 'package:elec_server/api/utilities/api_customer_counts_eversource.dart';




updateDb() async {

  var archive = new EversourceCtCustomerCountsArchive();
//  customerCountsUrl.keys.forEach((month) async {
//    await archive.downloadFile(month);
//  });

//  File file = archive.getFile(new Month(2014,1));
//  var data = archive.readXlsx(file);
//  data.forEach(print);

  // archive.setup();

  await archive.dbConfig.db.open();
  var futs = customerCountsUrl.keys.map((month) async {
    File file = archive.getFile(month);
    var data = archive.readXlsx(file);
    return await archive.insertData(data);
  });
  await Future.wait(futs);
  await archive.dbConfig.db.close();


}

apiTest() async {
  ComponentConfig config = new ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'eversource'
    ..collectionName = 'customer_counts_ct';

  var api = new ApiCustomerCounts(config.db);

  await config.db.open();
  var res = await api.customerCountsCt();
  print(res);

  await config.db.close();
}


main() async {

  //await updateDb();

  await apiTest();
}