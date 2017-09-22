library test.customer_counts;

import 'dart:io';
import 'package:elec_server/src/db/customer_counts.dart';

updateDb() async {

  var archive = new NGridCustomerCountsArchive();
  String url = 'https://www9.nationalgridus.com/energysupply/current/20170811/Monthly_Aggregation_customer count and usage.xlsx';
  //await archive.downloadFile(url);

  File file = archive.getLatestFile();
  var res = archive.readXlsx(file);
  res.forEach(print);

}

main() async {

  await updateDb();
}