import 'dart:async';
import 'dart:io';
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
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'pnode_table');
    dbConfig = config;
    dir ??= env['HOME']! + '/Downloads/Archive/Nyiso/PnodeTable/Raw/';
    this.dir = dir!;
    reportName = 'NYISO ptid file';
  }

  Db get db => dbConfig.db;

  /// Get the csv file with ptid info for all the generators.
  ///
  Future<void> downloadData() async {
    var asOfDate = Date.today(location: UTC);
    var url = 'http://mis.nyiso.com/public/csv/generator/generator.csv';
    var file = File('$dir/generator_$asOfDate.csv');
    await downloadUrl(url, file);
  }

  /// Last date the data was downloaded
  Date lastDate() {
    var files = Directory(dir).listSync();
    var dates = files
        .whereType<File>()
        .map((e) =>
            path.basenameWithoutExtension(e.path).replaceAll('generator_', ''))
        .toList();
    dates.sort();
    return Date.parse(dates.last, location: UTC);
  }

  List<Map<String, dynamic>> processData(Date asOfDate) {
    var out = <Map<String, dynamic>>[];
    var converter = CsvToListConverter();

    // add the zones
    for (var zoneName in zoneNameToPtid.keys) {
      var ptid = zoneNameToPtid[zoneName];
      out.add({
        'asOfDate': asOfDate.toString(),
        'ptid': ptid,
        'name': zoneName,
        if (zonePtidToSpokenName.containsKey(ptid))
          'spokenName': zonePtidToSpokenName[ptid],
        'type': 'zone',
      });
    }

    // add the generator nodes
    var file = File('$dir/generator_$asOfDate.csv');
    var content = file.readAsStringSync();
    var xs = converter.convert(content);
    if (xs.isEmpty) return out;

    for (var x in xs.skip(1)) {
      var one = {
        'asOfDate': asOfDate.toString(),
        'ptid': x[1] as int,
        'name': x[0] as String,
        'type': 'gen',
        'zoneName': x[3] as String,
        'zonePtid': zoneNameToPtid[x[3] as String],
        'subzoneName': x[2] as String,
      };
      if (x[4] is num && x[5] is num) {
        one['lat/lon'] = [x[4] as num, x[5] as num];
      }
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

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    throw UnimplementedError();
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    throw UnimplementedError();
  }

  static final zoneNameToPtid = <String, int>{
    'CAPITL': 61757,
    'CENTRL': 61754,
    'DUNWOD': 61760,
    'GENESE': 61753,
    'H Q': 61844,
    'HUD VL': 61758,
    'LONGIL': 61762,
    'MHK VL': 61756,
    'MILLWD': 61759,
    'N.Y.C.': 61761,
    'NORTH': 61755,
    'NPX': 61845,
    'O H': 61846,
    'PJM': 61847,
    'WEST': 61752,
  };

  static final zonePtidToSpokenName = <int, String>{
    61752: 'Zone A',
    61753: 'Zone B',
    61754: 'Zone C',
    61755: 'Zone D',
    61756: 'Zone E',
    61757: 'Zone F',
    61758: 'Zone G',
    61759: 'Zone H',
    61760: 'Zone I',
    61761: 'Zone J',
    61762: 'Zone K',
  };
}
