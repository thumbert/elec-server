library db.utilities.eversource.supplier_backlog_rates;

import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:tuple/tuple.dart';
import 'package:path/path.dart' as path;

/// See https://energizect.com/rate-board-residential-standard-service-generation-rates
/// Each month has customer counts by competitive provider

enum Utility {
  eversource,
  ui,
}

class CtSupplierBacklogRatesArchive extends IsoExpressReport {
  CtSupplierBacklogRatesArchive({ComponentConfig? dbConfig}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1',
            dbName: 'retail_suppliers',
            collectionName: 'ct_backlog_rates');
    dir = '$baseDir../SupplierBacklogRates/CT/Raw/';
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    // TODO: implement converter
    throw UnimplementedError();
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    // TODO: implement processFile
    throw UnimplementedError();
  }

  /// Download an SCC report xls file from the ISO.  Save it with the same
  /// name in the xlsx format.
  Future downloadFile(Uri url) async {
    var filename = path.basename(url.toString());
    var fileout = File(dir + filename);

    if (fileout.existsSync()) {
      print("File $filename is already downloaded.");
    }

    return HttpClient()
        .getUrl(url)
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
        response.pipe(fileout.openWrite()));
  }


  @override
  Future<void> setupDb() {
    // TODO: implement setupDb
    throw UnimplementedError();
  }
}

/// Maybe find a smarter way to do it ...
final urls = <Tuple2<Month, Utility>, Uri>{
  Tuple2(Month.utc(2023, 2), Utility.eversource): Uri.parse(
      'https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20February%202023%20ER.xlsx'),
  Tuple2(Month.utc(2023, 1), Utility.eversource): Uri.parse(
      'https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20January%202023%20ER.xlsx'),
  Tuple2(Month.utc(2022, 12), Utility.eversource): Uri.parse(
      'https://energizect.com/sites/default/files/documents/Supplier%20Billed%20Rates-%20December%202022%20ER.xlsx'),
};
