library db.isoexpress.mra_capacity_results;

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/isoexpress/mra_capacity_bidoffer.dart';
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class MraCapacityBidOfferArchive {
  MraCapacityBidOfferArchive({String? dir}) {
    this.dir = dir ?? '${baseDir}Capacity/Results/MonthlyAuction';
  }

  late final String dir;
  final String report =
      'Forward Capacity Market Monthly Reconfiguration Auction Results';

  
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


  // Future insertData(List<Map<String, dynamic>> data) async {
  //   if (data.isEmpty) {
  //     print('--->  No data to insert');
  //     return Future.value(-1);
  //   }
  // }

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
    final duckFile = File('$dir/tmp/mra_duck_${month.toIso8601String()}.csv');
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
              'Auction': Map<String,dynamic> auction,
              'ClearedCapacityZones': List ccz,
              'SystemResults': Map<String,dynamic> systemResults, 
            },
          }
        }) {
      return ccz.expand((e) => MraCapacityRecord.fromJson(e)).toList();
    } else {
      throw const FormatException('Wrong json input!');
    }
  }
}
