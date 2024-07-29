library db.isoexpress.mra_capacity_results;

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/client/isoexpress/mra_capacity_bidoffer.dart';
import 'package:logging/logging.dart';

class MraCapacityResultsArchive {
  MraCapacityResultsArchive({required this.dir});

  final String dir;
  final String report =
      'Forward Capacity Market Monthly Reconfiguration Auction Results';
  static final log = Logger('ISONE MRA results');

  /// https://webservices.iso-ne.com/api/v1.1/fcmmra/cp/2023-24/month/202401
  String getUrl(Month month) {
    var cp = '${month.year - 1}-${month.year % 100}';
    if (month.month >= 6) {
      cp = '${month.year}-${(month.year + 1) % 100}';
    }
    return 'https://webservices.iso-ne.com/api/v1.1/fcmmra/cp/$cp/month/${month.toIso8601String().replaceAll('-', '')}';
  }

  File getFilename(Month month) =>
      File('$dir/Raw/fcmmra_${month.toIso8601String()}.json');

  int makeCsvFileForDuckDb(Month month) {
    final file = getFilename(month);
    if (!file.existsSync()) {
      throw StateError(
          'ISO file for month $month has not been downloaded.  Download that file first!');
    }
    final rs = processJsonFile(file);
    var ls = [
      rs.first.toJson().keys.toList(),
      ...rs.map((e) => e.toJson().values.toList())
    ];
    String csv = const ListToCsvConverter().convert(ls);
    final duckFile = File('$dir/month/mra_duck_${month.toIso8601String()}.csv');
    duckFile.writeAsStringSync(csv);
    return 0;
  }

  ///
  List<MraCapacityRecord> processJsonFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    if (aux
        case {
          'FCMRAResultss': {
            'FCMRAResult': {
              'Auction': Map<String, dynamic> _,
              'ClearedCapacityZones': List ccz,
              'SystemResults': Map<String, dynamic> _,
            },
          }
        }) {
      return ccz.expand((e) => MraCapacityRecord.fromJson(e)).toList();
    } else {
      throw const FormatException('Wrong json input!');
    }
  }

  int updateDuckDb({required List<Month> months, required String pathDbFile}) {
    final con = Connection(pathDbFile);
    con.execute(r'''
CREATE TABLE IF NOT EXISTS mra (
  month UINTEGER, 
  maskedResourceId UINTEGER, 
  maskedParticipantId UINTEGER, 
  maskedCapacityZoneId USMALLINT, 
  resourceType ENUM('generating', 'demand', 'import'), 
  maskedExternalInterfaceId USMALLINT, 
  bidOffer ENUM('bid', 'offer'), 
  segment UTINYINT, 
  quantity FLOAT, 
  price FLOAT
);
''');
    for (var month in months) {
      log.info('Inserting month ${month.toIso8601String()}...');
      // remove the data if it's already there
      con.execute('''
DELETE FROM mra 
WHERE month == ${month.toInt()};
      ''');
      // reinsert the data
      con.execute('''
INSERT INTO mra
FROM read_csv(
    '$dir/month/mra_duck_${month.toIso8601String()}.csv', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
''');
    }
    con.close();
    return 0;
  }
}
