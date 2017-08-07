library iso.nepool.nepool_bindingconstraints;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';

import 'archive.dart';
import 'config.dart';

Config config;

/**
 * Get start/end date of the data
 *   db.binding_constraints.aggregate([{$group: {_id: null, minHour:{$min: '$hourEnding'}, maxHour: {$max: '$hourEnding'}}}])
 * Get all distinct constraints
 *   db.binding_constraints.distinct('ConstraintName').sort('ConstraintName', 1)
 * Get binding constraints after a date
 *   db.binding_constraints.find({hourEnding: {$gte: new Date("2015-03-05T00:00:00.000Z")}})
 */

class NepoolBindingConstraints {
  Db db;
  DbCollection coll;
  String DIR = '/Downloads/Archive/DA_BindingConstraints/Raw/';
  Map<String, String> env;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");

  NepoolBindingConstraints({this.db}) {
    if (db == null) db = new Db('mongodb://127.0.0.1/nepool');

    coll = db.collection('binding_constraints');

    env = Platform.environment;
    //print('${env["ISO1_LOGIN"]} and ${env["ISO1_PASSWD"]}');
  }

  /**
   * Get the binding constraints between two dates [start, end], maybe filter them
   * by constraint names.
   * db.binding_constraints.find({ConstraintName: {$in: ['KR-EXP', 'NHSC-I']}}, {_id: 0}).limit(10)
   * Return a list.
   */
  Future<List> getBindingConstraints(DateTime start, DateTime end,
      {List<String> constraintNames}) {
    SelectorBuilder query = where;

    if (start != null) query = query.gte('hourEnding', start.toUtc());

    if (end != null) query = query.lte('hourEnding', end.toUtc());

    if (constraintNames != null && constraintNames.isNotEmpty) query =
        query.oneFrom('ConstraintName', constraintNames);

    query =
        query.fields(['hourEnding', 'ConstraintName']).excludeFields(['_id']);

    return coll.find(query).toList();
  }

  /**
   * Bring the db up to date.
   * Find the latest day in the archive and update from there to nextDay
   */
  updateDb() {
    return db.open().then((_) => lastDayInserted().then((DateTime lastDay) {
          Date start = new Date.fromDateTime(lastDay).next;;
          Date end = Date.today();
          print('Updating the db from $start to $end.');
          return insertDaysStartEnd(start, end);
        }));
  }

  /**
   * Archive and Insert days between start, end.
   * Parameters start and end are midnight UTC DateTime objects.
   * For each day in the range of days, download and insert the data into the db.
   */
  insertDaysStartEnd(Date start, Date end) {
    List<Date> days = new TimeIterable(start, end).toList();
    Date.fmt = new DateFormat('yyyyMMdd');

    return Future.forEach(days, (day) {
      String yyyymmdd = day.toString();
      return oneDayDownload(yyyymmdd).then((_) {
        return oneDayMongoInsert(yyyymmdd);
      });
    }).then((_) {
      print('Done!');
    });
  }

  /**
   * Make the daily insertions idempotent, so you never insert the same data over
   * and over again.  You should run this only once when you set up the database.
   * db.binding_constraints.ensureIndex({hourEnding: 1, ConstraintName : 1, ContingencyName: 1}, {unique: true})
   */
  prepareCollection() {
    return db.open().then((_) {
      return db.ensureIndex('binding_constraints',
          keys: {'hourEnding': 1, 'ConstraintName': 1, 'ContingencyName': 1},
          unique: true);
    }).then((_) {
      db.close();
    });
  }

  /**
   * Return the last day that was ingested in the db.
   * db.binding_constraints.aggregate([{$group: {_id: null, lastHour: {$max: '$hourEnding'}}}])
   */
  Future<DateTime> lastDayInserted() {
    DateTime lastDay;

    DbCollection coll = db.collection('binding_constraints');
    List pipeline = [];
    var group = {
      '\$group': {
        '_id': null,
        'last': {'\$max': '\$hourEnding'}
      }
    };
    pipeline.add(group);
    return coll.aggregate(pipeline).then((v) {
      print('$v');
      Map aux = v['result'].first;
      lastDay = aux['last']; // a local datetime
      return new DateTime.utc(lastDay.year, lastDay.month, lastDay.day);
    });
  }

  /**
   * Inserts one day into the db.
   */
  Future oneDayMongoInsert(String yyyymmdd) {
    List data = oneDayJsonRead(yyyymmdd);
    if (data.isEmpty) return new Future.value(
        print('No binding constraints for $yyyymmdd.  Skipping.'));

    DbCollection coll = db.collection('binding_constraints');
    print('Inserting $yyyymmdd into db');
    return coll
        .insertAll(data)
        .then((_) => print('--->  SUCCESS'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /**
   * Read the json file and prepare it for ingestion into mongo.
   * DateTimes need to be hourEnding UTC, etc.
   */
  List<Map> oneDayJsonRead(String yyyymmdd) {
    List<Map> data;
    File filename =
        new File(env['HOME'] + DIR + "nepool_da_bc_${yyyymmdd}.json");
    Map aux = JSON.decode(filename.readAsStringSync());
    if (aux['DayAheadConstraints'] == "") {
      return data = [];
      // on some days there are no constraints 2/17/2015
    } else {
      data = aux['DayAheadConstraints']['DayAheadConstraint'];
    }

    data.forEach((Map row) {
      row['hourEnding'] =
          fmt.parse(row['BeginDate']).toUtc().add(new Duration(minutes: 60));
      row['ContingencyName'] = row['ContingencyName'].toString();
      // sometimes it reads as a number!
    });
    //data.forEach((e) => print(e));

    return data;
  }

  Future oneDayDownload(String yyyymmdd) {
    File fileout =
        new File(env['HOME'] + DIR + "nepool_da_bc_${yyyymmdd}.json");

    if (fileout.existsSync()) {
      return new Future.value(print('Day $yyyymmdd was already downloaded.'));
    } else {
      String URL =
          "https://webservices.iso-ne.com/api/v1.1/dayaheadconstraints/day/${yyyymmdd}";
      HttpClient client = new HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        //print('Bad certificate connecting to $host:$port:');
        //_printCertificate(cert);
        //print('');
        return true;
      };
      client.addCredentials(
          Uri.parse(URL),
          "",
          new HttpClientBasicCredentials(
              env['ISO1_LOGIN'], env["ISO1_PASSWD"]));
      client.userAgent = "Mozilla/4.0";

      return client.getUrl(Uri.parse(URL)).then((HttpClientRequest request) {
        request.headers.set(HttpHeaders.ACCEPT, "application/json");
        return request.close();
      })
          .then((HttpClientResponse response) =>
              response.pipe(fileout.openWrite()))
          .then((_) =>
              print('Downloaded binding constraints for day $yyyymmdd.'));
    }
  }

  _printCertificate(cert) {
//    print('${cert.issuer}');
//    print('${cert.subject}');
//    print('${cert.startValidity}');
//    print('${cert.endValidity}');
  }
}

/**
 * Deal with downloading the data, massaging it, and loading it into mongo.
 */
class DaBindingConstraintArchive extends ComponentConfig with DailyArchive {
  DbCollection coll;
  Location location;
  Map<String, String> env;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  Db db;

  DaBindingConstraintArchive() {
    if (config == null) config = new TestConfig();
    ComponentConfig component = config.isone_binding_constraints_da;
    dbName = component.dbName;
    DIR = component.DIR;
    collectionName = component.collectionName;
    db = component.db;

    coll = db.collection(collectionName);
    initializeTimeZoneSync();
    location = getLocation('US/Eastern');
    env = Platform.environment;
  }

  String yyyymmdd(Date date) {
    var mm = date.month.toString().padLeft(2, '0');
    var dd = date.day.toString().padLeft(2, '0');
    return '${date.year}$mm$dd';
  }

  /**
   * Read the csv file and prepare it for ingestion into mongo.
   * DateTimes need to be hourBeginning UTC, etc.
   */
  List<Map> oneDayRead(Date date) {
    List<Map> data;
    File file = new File(DIR + "nepool_da_bc_${yyyymmdd(date)}.json");
    if (file.existsSync()) {
      Map aux = JSON.decode(file.readAsStringSync());
      if (aux['DayAheadConstraints'] == "") {
        /// on some days there are no constraints 2/17/2015
        return data = [];
      } else {
        data = aux['DayAheadConstraints']['DayAheadConstraint'];
      }

      data.forEach((Map row) {
        row['hourBeginning'] = new TZDateTime.from(fmt.parse(row['BeginDate']), location);
        row.remove('BeginDate');
        // sometimes it reads the Contingency Name as a number!
        row['ContingencyName'] = row['ContingencyName'].toString();
      });

      return data;
    } else {
      throw 'Could not find file for day $date';
    }
  }

  String _unquote(String x) => x.substring(1, x.length - 1);

  /**
   * Ingest one day prices in mongo
   */
  Future oneDayMongoInsert(Date date) {
    List<Map> data;
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

  /**
   * Download the file if not in the archive folder.  If file is already downloaded, no nothing.
   */
  Future oneDayDownload(Date date) async {
    File fileout = new File(DIR + "nepool_da_bc_${yyyymmdd(date)}.json");
    if (fileout.existsSync()) {
      print('  file already downloaded for $date');
      return new Future.value(print('Day $date was already downloaded.'));
    } else {
      String URL =
          "https://webservices.iso-ne.com/api/v1.1/dayaheadconstraints/day/${yyyymmdd(date)}";
      HttpClient client = new HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.addCredentials(
          Uri.parse(URL),
          "",
          new HttpClientBasicCredentials(
              env['ISO1_LOGIN'], env["ISO1_PASSWD"]));
      client.userAgent = "Mozilla/4.0";

      HttpClientRequest request = await client.getUrl(Uri.parse(URL));
      request.headers.set(HttpHeaders.ACCEPT, 'application/json');
      HttpClientResponse response = await request.close();
      await response.pipe(fileout.openWrite());
      print('Downloaded nepool da binding constraints for $date.');
    }
  }

  /**
   * Return the last day that was ingested in the db.
   * db.DA_LMP.aggregate([{$group: {_id: null, firstHour: {$min: '$hourBeginning'}, lastHour: {$max: '$hourBeginning'}}}])
   */
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

  /**
   * Remove all the data for a given day (in case the insert fails midway)
   */
  removeDataForDay(Date date) async {
    SelectorBuilder sb = where;

    TZDateTime start =
        new TZDateTime(location, date.year, date.month, date.day).toUtc();
    sb = sb.gte('hourBeginning', start);

    Date next = date.next;
    TZDateTime end =
        new TZDateTime(location, next.year, next.month, next.day).toUtc();
    sb = sb.lt('hourBeginning', end);

    await coll.remove(sb);
  }

  /**
   * Recreate the collection from scratch.
   */
  setup() async {
    if (!new Directory(DIR).existsSync()) new Directory(DIR)
        .createSync(recursive: true);
    await oneDayDownload(new Date(2014, 1, 1));

    await db.open();
    List<String> collections = await db.getCollectionNames();
    print('Collections in db:');
    print(collections);
    if (collections.contains(collectionName)) await coll.drop();
    await oneDayMongoInsert(new Date(2014, 1, 1));

    // this indexing assures that I don't insert the same data twice
    await db.createIndex(collectionName,
      keys: {'hourBeginning': 1, 'ConstraintName': 1, 'ContingencyName': 1}, unique: true);

    await db.close();
  }

  /**
   * Bring the table up to date.
   */
  updateDb(Date start, Date end) async {
    // TODO: make start/end dependent on the data.
    await db.open();
    Date day = start;
    while (day.isBefore(end)) {
      await oneDayDownload(day);
      await oneDayMongoInsert(day);
      day = day.next;
    }
    await db.close();
  }
}
