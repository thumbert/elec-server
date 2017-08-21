library mongo.nepool_dalmp;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:date/date.dart';

import '../utils/iso_timestamp.dart';
import 'archive.dart';
import 'config.dart';


/// Deal with downloading the data, massaging it, and loading it into mongo.
class DamArchive extends ComponentConfig with DailyArchive {
  DbCollection coll;
  tz.Location location;

  DamArchive({Config config}) {
    if (config == null) config = new TestConfig();
    ComponentConfig component = config.isone_dam_lmp_hourly;
    host = component.host;
    dbName = component.dbName;
    DIR = component.DIR;
    collectionName = component.collectionName;

    coll = db.collection(collectionName);
    tz.initializeTimeZoneSync(config.tzdb);
    location = tz.getLocation('America/New_York');
  }

  String yyyymmdd(Date date) {
    var mm = date.month.toString().padLeft(2, '0');
    var dd = date.day.toString().padLeft(2, '0');
    return '${date.year}$mm$dd';
  }


  /// Read the csv file and prepare it for ingestion into mongo.
  /// DateTimes need to be hourBeginning UTC, etc.
  List<Map> oneDayRead(Date date) {
    File file = new File(DIR + "/WW_DALMP_ISO_${yyyymmdd(date)}.csv");
    if (file.existsSync()) {
      List<String> keys = [
        'hourBeginning',
        'ptid',
        'lmp',
        'congestion',
        'loss'
      ];

      List<Map> data = file
          .readAsLinesSync()
          .map((String row) => row.split(','))
          .where((List row) => row.first == '"D"')
          .map((List row) {
        return new Map.fromIterables(keys, [
          parseHourEndingStamp(_unquote(row[1]), _unquote(row[2])),
          int.parse(_unquote(row[3])), // ptid
          num.parse(row[6]),
          num.parse(row[8]),
          num.parse(row[9])
        ]);
      }).toList();

      return data;
    } else {
      throw 'Could not find file for day $date';
    }
  }

  String _unquote(String x) => x.substring(1, x.length - 1);

  /// Ingest one day prices in mongo
  Future oneDayMongoInsert(Date date) {
    List data;
    try {
      data = oneDayRead(date);
    } catch (e) {
      return new Future.value(print('ERROR:  No file for day $date}'));
    }

    print('Inserting day $date into db');
    return coll
        .insertAll(data)
        .then((_) => print('--->  SUCCESS'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /// Download the file if not in the archive folder.  If file is already downloaded, no nothing.
  Future oneDayDownload(Date date) async {
    File fileout = new File(DIR + "/WW_DALMP_ISO_${yyyymmdd(date)}.csv");
    if (fileout.existsSync()) {
      print('  file already downloaded');
      return new Future.value(print('Day $date was already downloaded.'));
    } else {
      String URL =
          "http://www.iso-ne.com/static-transform/csv/histRpts/da-lmp/WW_DALMP_ISO_${yyyymmdd(date)}.csv";
      HttpClient client = new HttpClient();
      HttpClientRequest request = await client.getUrl(Uri.parse(URL));
      HttpClientResponse response = await request.close();
      await response.pipe(fileout.openWrite());
      print('Downloaded ISONE DAM prices for $date.');
    }
  }


  /// Return the last day that was ingested in the db.
  /// db.DA_LMP.aggregate([{$group: {_id: null, firstHour: {$min: '$hourBeginning'}, lastHour: {$max: '$hourBeginning'}}}])
  Future<Date> lastDayInserted() async {
    DateTime lastDay;

    List pipeline = [];
    var group = {
      '\$group': {
        '_id': null,
        'last': {'\$max': '\$hourBeginning'}
      }
    };
    pipeline.add(group);

    Map v = await coll.aggregate(pipeline);
    Map aux = v['result'].first;
    lastDay = aux['last']; // a local datetime
    return new Date(lastDay.year, lastDay.month, lastDay.day);
  }


  /// Remove all the data for a given day (in case the insert fails midway)
  removeDataForDay(Date date) async {
    SelectorBuilder sb = where;

    tz.TZDateTime start =
        new tz.TZDateTime(location, date.year, date.month, date.day).toUtc();
    sb = sb.gte('hourBeginning', start);

    Date next = date.next;
    tz.TZDateTime end =
        new tz.TZDateTime(location, next.year, next.month, next.day).toUtc();
    sb = sb.lt('hourBeginning', end);

    await coll.remove(sb);
  }


  /// Recreate the collection from scratch.
  setup() async {
    if (!new Directory(DIR).existsSync())
      new Directory(DIR).createSync(recursive: true);
    await oneDayDownload(new Date(2014, 1, 1));

    await db.open();
    List<String> collections = await db.getCollectionNames();
    print('Collections in db:');
    print(collections);
    if (collections.contains(collectionName)) await coll.drop();
    await oneDayMongoInsert(new Date(2014, 1, 1));

    // this indexing assures that I don't insert the same data twice
    await db.createIndex(collectionName,
        keys: {'hourBeginning': 1, 'ptid': 1}, unique: true);
    await db.createIndex(collectionName, keys: {'ptid': 1});

    await db.close();
  }


  /// Bring the table up to date.
  updateDb(Date start, Date end) async {
    // TODO: make start/end dependent on the data.
    await db.open();
    Date day = start;
    while (day.isBefore(end) || day == end) {
      await oneDayDownload(day);
      await oneDayMongoInsert(day);
      day = day.next;
    }
    await db.close();
  }
}
