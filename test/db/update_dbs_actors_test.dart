import 'dart:async';
import 'dart:io';

import 'package:actors/actors.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:dotenv/dotenv.dart' as dotenv;


class ArchiveHandler with Handler<Date, int> {
  ArchiveHandler();

  DaLmpHourlyArchive? _archive;

  Future<DaLmpHourlyArchive> _init() async {
    dotenv.load('.env/prod.env');
    initializeTimeZones();
    var archive = DaLmpHourlyArchive();
    await archive.dbConfig.db.open();
    return archive;
  }

  @override
  Future<int> handle(Date date) async {
    var archive = _archive;
    if (archive == null) {
      archive = await _init();
      _archive = archive;
    }
    await archive.downloadDay(date);
    await archive.insertDay(date);
    return 0;
  }

  @override
  FutureOr<void> close() async {
    await _archive!.dbConfig.db.close();
    return super.close();
  }
}


Future<void> main() async {
  initializeTimeZones();

  // /// One actor
  // final actor = Actor(ArchiveHandler());
  // await actor.send(Date.utc(2022, 3, 1));
  // await actor.close();


  /// An ActorGroup
  var sw = Stopwatch()..start();
  final group = ActorGroup(ArchiveHandler(), size: Platform.numberOfProcessors);
  final futures = <FutureOr<int>>[];

  var days = Term.parse('Mar22', UTC).days();
  for (var day in days) {
    futures.add(group.send(day));
  }
  for (final future in futures) {
    await future;
  }
  group.close();
  sw.stop();
  print('Elapsed ${sw.elapsedMilliseconds}');
}
