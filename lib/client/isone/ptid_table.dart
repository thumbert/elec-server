import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:date/date.dart';
part 'ptid_table.g.dart';

Future<List<Record>> getPtidsActivatedOn(Date activatedOn, {
  required String rootUrl,
}) async {
  final filter = QueryFilter(activatedOn: activatedOn);
  final records = await queryRecords(
    filter: filter,
    rootUrl: rootUrl,
  );
  return records;
}

Future<List<Record>> getPtidsDeactivatedOn(Date deactivatedOn, {
  required String rootUrl,
}) async {
  final filter = QueryFilter(deactivatedOn: deactivatedOn);
  final records = await queryRecords(
    filter: filter,
    rootUrl: rootUrl,
  );
  return records;
}   
