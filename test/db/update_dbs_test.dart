import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:actors/actors.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:more/more.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:dotenv/dotenv.dart' as dotenv;


Future<void> insertDays(DailyIsoExpressReport archive, List<Date> days) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> tests() async {
  var sw = Stopwatch()..start();
  var location = getLocation('America/New_York');

  // var days = Date.today(location: location).next.previousN(4);
  var days = Term.parse('Apr22', UTC).days();
  await insertDays(DaLmpHourlyArchive(), days);
  sw.stop();
  print('Elapsed ${sw.elapsedMilliseconds}');
}

class FileHandler with Handler<String, int> {
  FileHandler();

  Db? _db;

  Future<Db> _init() async {
    var db = Db('mongodb://127.0.0.1/test');
    await db.open();
    return db;
  }

  @override
  Future<int> handle(
    String dateTime,
  ) async {
    var db = _db;
    if (db == null) {
      db = await _init();
      _db = db;
    }

    await Future.delayed(Duration(seconds: 1));
    var x = <String, dynamic>{
      'datetime': dateTime,
      'values': List.generate(100, (index) => Random().nextInt(100)),
    };
    var collection = db.collection('actors');
    await collection.insert(x);
    print('Finished with $dateTime');
    return 0;
  }

  @override
  FutureOr<void> close() async {
    await _db!.close();
    return super.close();
  }
}

// Future<void> main() async {
//   // /// One actor
//   // final actor = Actor(FileHandler());
//   // await actor.send('2023-01-02');
//   // await actor.close();
//
//   /// An ActorGroup
//   var sw = Stopwatch()..start();
//   final group = ActorGroup(FileHandler(), size: Platform.numberOfProcessors);
//
//   final futures = <FutureOr<int>>[];
//   var days = <DateTime>[
//     for (var i = 0; i < 31; i++) DateTime.utc(2023).add(Duration(days: i))
//   ];
//   for (var day in days) {
//     futures.add(group.send(day.toString()));
//   }
//   for (final future in futures) {
//     await future;
//   }
//   group.close();
//   sw.stop();
//   print('Elapsed ${sw.elapsedMilliseconds}');
// }

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');


  ///
  /// See bin/setup_db.dart on how to update a database
  ///

  await tests();
}
