library db.isoexpress.mra_capacity_bidoffer;

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/isoexpress/mra_capacity_bidoffer.dart';
import '../lib_iso_express.dart';

class MraCapacityBidOfferArchive {
  MraCapacityBidOfferArchive({String? dir}) {
    this.dir = dir ?? '${baseDir}Capacity/HistoricalBidsOffers/MonthlyAuction';
  }

  late final String dir;
  final String report =
      'Forward Capacity Market Monthly Reconfiguration Auction Historical Bid Report';

  String getUrl(Month month) =>
      'https://webservices.iso-ne.com/api/v1.1/hbfcmmra/month/${month.toIso8601String().replaceAll('-', '')}';

  File getFilename(Month month) =>
      File('$dir/Raw/hbfcmmra_${month.toIso8601String()}.json');

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
          'Hbfcmmras': {
            'Hbfcmmra': List xs,
          }
        }) {
      return xs.expand((e) => MraCapacityRecord.fromJson(e)).toList();
    } else {
      throw const FormatException('Wrong json input!');
    }
  }
}
