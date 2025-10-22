import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/lib_nyiso_reports.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';

class PtidArchive extends NyisoReport {
  PtidArchive({ComponentConfig? config, String? dir}) {
    Map env = Platform.environment;
    config ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'pjm', collectionName: 'pnode_table');
    dbConfig = config;
    dir ??= env['HOME']! + '/Downloads/Archive/Pjm/PnodeTable/Raw/';
    this.dir = dir!;
    reportName = 'PJM ptid file';
  }

  Db get db => dbConfig.db;

  /// Get the csv file with ptid info for all the generators.
  /// http://dataminer2.pjm.com/feed/pnode
  /// NOTE: does not work.  Need to click on the download button on the page
  Future<void> downloadData() async {
    var asOfDate = Date.today(location: UTC);
    var url = 'http://dataminer2.pjm.com/feed/pnode';
    var file = File('$dir/pnode_$asOfDate.csv');
    await downloadUrl(url, file);
  }

  List<Map<String, dynamic>> processData(Date asOfDate) {
    var out = <Map<String, dynamic>>[];
    var converter = CsvToListConverter();

    var file = File('$dir/pnode_$asOfDate.csv');
    var content = file.readAsStringSync();
    var xs = converter.convert(content);
    if (xs.isEmpty) return out;

    var keys = xs.first.cast<String>();
    if (!ListEquality().equals(keys, <String>[
      'pnode_id',
      'pnode_name',
      'pnode_type',
      'pnode_subtype',
      'zone',
      'voltage_level',
      'effective_date',
      'termination_date',
    ])) {
      throw ArgumentError('File contents have changed!');
    }

    for (var x in xs.skip(1)) {
      var one = {
        'asOfDate': asOfDate.toString(),
        'ptid': x[0] as int,
        'name': x[1] as String,
        'type': x[2] as String, // BUS, AGGREGATE
        'subtype': x[3] as String, // LOAD, GEN, AGGREGATE, HUB, ZONE, EHV
        'zoneName': x[4] as String,
        'voltageLevel': x[5] as String,
        'effectiveDate': x[6] as String,
        'terminationDate': x[7] as String,
      };
      out.add(one);
    }

    return out;
  }

  @override
  Future<void> setupDb() async {
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }

    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'asOfDate': 1, 'ptid': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'asOfDate': 1});
    await dbConfig.db.close();
  }

  /// Last date the data was downloaded
  Date lastDate() {
    var files = Directory(dir).listSync();
    var dates = files
        .whereType<File>()
        .map((e) =>
            path.basenameWithoutExtension(e.path).replaceAll('pnode_', ''))
        .toList();
    dates.sort();
    return Date.parse(dates.last, location: UTC);
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    throw UnimplementedError();
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    throw UnimplementedError();
  }

  // static final zoneNameToPtid = <String, int>{
  //   'CAPITL': 61757,
  //   'CENTRL': 61754,
  //   'DUNWOD': 61760,
  //   'GENESE': 61753,
  //   'H Q': 61844,
  //   'HUD VL': 61758,
  //   'LONGIL': 61762,
  //   'MHK VL': 61756,
  //   'MILLWD': 61759,
  //   'N.Y.C.': 61761,
  //   'NORTH': 61755,
  //   'NPX': 61845,
  //   'O H': 61846,
  //   'PJM': 61847,
  //   'WEST': 61752,
  // };

  static final zonePtidToSpokenName = <int, String>{
    51287: 'WEST INT HUB',
    51288: 'WESTERN HUB',
    51291: 'AECO',
    51292: 'BGE',
    51293: 'DPL',
    51295: 'JCPL',
    51296: 'METED',
    51297: 'PECO',
    51298: 'PEPCO',
    51299: 'PPL',
    51300: 'PENELEC',
    51301: 'PSEG',
  };
}
