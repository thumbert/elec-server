library db.isoexpress.mra_capacity_results;

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/client/isoexpress/mra_capacity_results.dart';
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

  /// Create two files, one for zones, one for interfaces
  int makeCsvFileForDuckDb(Month month) {
    final fileIn = getFilename(month);
    if (!fileIn.existsSync()) {
      throw StateError(
          'ISO file for month $month has not been downloaded.  Download that file first!');
    }
    final rs = processFile(fileIn);
    // write the zones
    final zs = rs.whereType<MraCapacityZoneRecord>();
    var list = [
      zs.first.toJson().keys.toList(),
      ...zs.map((e) => e.toJson().values.toList())
    ];
    var csv = const ListToCsvConverter().convert(list);
    var fileOut = File('$dir/month/mra_zone_${month.toIso8601String()}.csv');
    fileOut.writeAsStringSync(csv);

    // write the interfaces
    final faces = rs.whereType<MraCapacityInterfaceRecord>();
    list = [
      faces.first.toJson().keys.toList(),
      ...faces.map((e) => e.toJson().values.toList())
    ];
    csv = const ListToCsvConverter().convert(list);
    fileOut = File('$dir/month/mra_interface_${month.toIso8601String()}.csv');
    fileOut.writeAsStringSync(csv);

    return 0;
  }

  ///
  List<MraCapacityRecord> processFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    if (aux
        case {
          'FCMRAResults': {
            'FCMRAResult': Map<String, dynamic> data,
          }
        }) {
      return [
        ...MraCapacityZoneRecord.fromJson(data),
        ...MraCapacityInterfaceRecord.fromJson(data),
      ];
    } else {
      throw const FormatException('Wrong json input!');
    }
  }

  int updateDuckDb({required List<Month> months, required String pathDbFile}) {
    final con = Connection(pathDbFile);

    ///
    /// Zones
    ///
    con.execute(r'''
CREATE TABLE IF NOT EXISTS results_zone (
  month UINTEGER NOT NULL, 
  capacityZoneId UINTEGER NOT NULL, 
  capacityZoneType ENUM('ROP', 'Export', 'Import') NOT NULL,
  capacityZoneName VARCHAR NOT NULL,
  supplyOffersSubmitted FLOAT NOT NULL, 
  demandBidsSubmitted FLOAT NOT NULL, 
  supplyOffersCleared FLOAT NOT NULL, 
  demandBidsCleared FLOAT NOT NULL, 
  netCapacityCleared FLOAT NOT NULL,
  clearingPrice FLOAT NOT NULL
);
''');
    for (var month in months) {
      log.info('Inserting month ${month.toIso8601String()}...');
      // remove the data if it's already there
      con.execute('''
DELETE FROM results_zone 
WHERE month == ${month.toInt()};
      ''');
      // reinsert the data
      con.execute('''
INSERT INTO results_zone
FROM read_csv(
    '$dir/month/mra_zone_${month.toIso8601String()}.csv', 
    header = true);
''');
    }

    ///
    /// Interfaces
    ///
    con.execute(r'''
CREATE TABLE IF NOT EXISTS results_interface (
  month UINTEGER NOT NULL, 
  externalInterfaceId UINTEGER NOT NULL, 
  externalInterfaceName VARCHAR NOT NULL,
  supplyOffersSubmitted FLOAT NOT NULL, 
  demandBidsSubmitted FLOAT NOT NULL, 
  supplyOffersCleared FLOAT NOT NULL, 
  demandBidsCleared FLOAT NOT NULL, 
  netCapacityCleared FLOAT NOT NULL,
  clearingPrice FLOAT NOT NULL
);
''');
    for (var month in months) {
      log.info('Inserting month ${month.toIso8601String()}...');
      // remove the data if it's already there
      con.execute('''
DELETE FROM results_interface 
WHERE month == ${month.toInt()};
      ''');
      // reinsert the data
      con.execute('''
INSERT INTO results_interface
FROM read_csv(
    '$dir/month/mra_interface_${month.toIso8601String()}.csv', 
    header = true);
''');
    }

    con.close();
    return 0;
  }
}
