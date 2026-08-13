import 'dart:convert';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
part 'ptid_table.g.dart';

Future<List<Record>> getPtidsActivatedOn(Date activatedOn) async {
  final filter = QueryFilter(activatedOn: activatedOn);
  final records = await queryRecords(
    filter: filter,
    rootUrl: dotenv.env['RUST_SERVER']!,
  );
  return records;
}

Future<List<Record>> getPtidsDeactivatedOn(Date deactivatedOn) async {
  final filter = QueryFilter(deactivatedOn: deactivatedOn);
  final records = await queryRecords(
    filter: filter,
    rootUrl: dotenv.env['RUST_SERVER']!,
  );
  return records;
}   
