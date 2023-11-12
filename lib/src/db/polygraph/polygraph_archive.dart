library lib.db.polygraph.polygraph_archive;

import 'dart:convert';
import 'dart:io';

import 'package:elec_server/src/db/config.dart';
import 'package:logging/logging.dart';

class PolygraphArchive {
  PolygraphArchive({ComponentConfig? dbConfig, Directory? dir}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1', dbName: 'polygraph', collectionName: 'projects');
    this.dir = dir ??
        Directory(
            '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Polygraph/Projects/Raw/');
  }

  late final ComponentConfig dbConfig;
  /// Store projects as json files
  late final Directory dir;
  final log = Logger('CME energy settlements');

  /// Read a json file with a Polygraph project
  Map<String,dynamic> readFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    aux['tabs'] = (aux['tabs'] as List).cast<Map<String,dynamic>>();
    return aux;
  }

  /// Insert one project at a time.
  /// ```dart
  /// {
  ///   'userId': 'e47187',
  ///   'projectName': 'Demo 1',
  ///   'tabs': {
  ///     'tabs': [
  ///       {
  ///         'name': 'Tab 1',
  ///         'tabLayout': {
  ///           'rows': 1,
  ///           'columns': 1,
  ///           'canvasSize': {'width': 900, 'height': 600},
  ///         },
  ///         windows: [
  ///           {
  ///             'term': 'Cal 24',
  ///             'tzLocation': 'UTC',
  ///             'xVariable': {},
  ///             'yVariables': [
  ///               {...},
  ///               ...
  ///             ],
  ///           }
  ///         ],
  ///       },
  ///       ...
  ///     ]
  ///   }
  /// }
  /// ```
  ///
  Future<int> insertData(Map<String, dynamic> data) async {
    if (data
        case {
          'userId': String userId,
          'projectName': String projectName,
          'tabs': List<Map<String,dynamic>> tabs,
        }) {
      assert(tabs.isNotEmpty, true);
      try {
        await dbConfig.coll
            .remove({'userName': userId, 'projectName': projectName});
        await dbConfig.coll.insertOne(data);
        log.info('--->  Inserted project "$userId/$projectName" into database');
        return 0;
      } catch (e) {
        log.severe('xxxx ERROR xxxx $e');
        return 1;
      }
    } else {
      throw ArgumentError('Invalid project format $data');
    }
  }

  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'userId': 1,
          'projectName': 1,
        },
        unique: true);
    await dbConfig.db.close();
  }
}
