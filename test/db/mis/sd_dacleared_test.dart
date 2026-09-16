import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
//import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:date/date.dart';
import 'package:elec_server/api/mis/api_sr_dalocsum.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/mis/sr_dalocsum.dart';
import 'package:path/path.dart';
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/client/mis/sr_dalocsum.dart' as client;


void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS tab0 (
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    account_id UINTEGER NOT NULL,
    location_id UINTEGER NOT NULL,
    location_name VARCHAR NOT NULL,
    location_type ENUM ('LOAD ZONE', 'NETWORK NODE', 'HUB', 'DRR AGGREGATION ZONE') NOT NULL,
    bid_offer_type ENUM ('DEMAND BID', 'GEN OFFER', 'INC', 'DEC', 'REDUCTION OFFER') NOT NULL,
    reference_id VARCHAR,
    asset_id UINTEGER NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    ownership_share DECIMAL(9,4) NOT NULL,
    cleared_mw DECIMAL(9,1) NOT NULL
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/isone/mis/sd_dacleared/tab0',
    onlyFilters: ['report_date', 'account_id', 'location_id', 'bid_offer_type'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

void main() async {
  initializeTimeZones();

  generateCode();
}
