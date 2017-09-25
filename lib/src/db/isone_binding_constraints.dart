library iso.nepool.nepool_bindingconstraints;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec/src/iso/isone/lib_mis_reports.dart' as mis;

import 'archive.dart';
import 'config.dart';
import '../utils/timezone_utils.dart';
import '../utils/iso_timestamp.dart';


/// Deal with downloading the data, massaging it, and loading it into mongo.
class DaBindingConstraintArchive extends DailyArchive {
  ComponentConfig config;

  DaBindingConstraintArchive({this.config}) {
    if (config == null) {
      Map env = Platform.environment;
      config = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isone'
        ..collectionName = 'binding_constraints'
        ..DIR = env['HOME'] + '/Downloads/Archive/DA_BindingConstraints/Raw/';
    }

    initializeTimeZoneSync( getLocationTzdb() );
  }

  Db get db => config.db;

  String yyyymmdd(Date date) {
    var mm = date.month.toString().padLeft(2, '0');
    var dd = date.day.toString().padLeft(2, '0');
    return '${date.year}$mm$dd';
  }

  /// Read the csv file and prepare it for ingestion into mongo.
  /// DateTimes need to be hourBeginning UTC, etc.
  List<Map> oneDayRead(Date date) {
    List<Map> data;
    File file = new File(config.DIR + "da_binding_constraints_final_${yyyymmdd(date)}.csv");
    if (file.existsSync()) {
      data = mis.readReportAsMap(file, tab: 0);
      if (data.isEmpty) {
        /// on some days there are no constraints, for example 2/17/2015
        return [];
      }

      data.forEach((Map row) {
        var localDate = (row['Local Date'] as String).substring(0,10);
        row['hourBeginning'] = parseHourEndingStamp(localDate, row['Hour Ending']);
        row.remove('Local Date');
        row.remove('H');
        // sometimes it reads the Contingency Name as a number!
        row['Contingency Name'] = row['Contingency Name'].toString();
        row['date'] = date.toString();
        row['market'] = 'DA';
      });

      return data;
    } else {
      throw 'Could not find file for day $date';
    }
  }

  String _unquote(String x) => x.substring(1, x.length - 1);

  /// Insert the DAM binding constraints for one day in mongo
  Future oneDayMongoInsert(Date date) {
    List<Map> data;
    try {
      data = oneDayRead(date);
    } catch (e) {
      return new Future.value(print('ERROR:  No file for day $date}'));
    }

    print('Inserting day $date into db');
    return config.coll
        .insertAll(data)
        .then((_) => print('--->  SUCCESS'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /// Download the file if not in the archive folder.  If file is already downloaded, no nothing.
  Future oneDayDownload(Date date) async {
    File fileout = new File(config.DIR + "da_binding_constraints_final_${yyyymmdd(date)}.csv");
    if (fileout.existsSync()) {
      print('  file already downloaded for $date');
      return new Future.value(print('Day $date was already downloaded.'));
    } else {
      String baseUrl = 'https://www.iso-ne.com/transform/csv/hourlydayaheadconstraints?';
      String url =
          '${baseUrl}start=${yyyymmdd(date)}&end=${yyyymmdd(date)}';
      HttpClient client = new HttpClient();
      HttpClientRequest request = await client.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
      await response.pipe(fileout.openWrite());
      print('Downloaded nepool da binding constraints for $date.');
    }
  }

  /// Return the last day that was ingested in the db.
  /// db.DA_LMP.aggregate([{$group: {_id: null, firstHour: {$min: '$hourBeginning'}, lastHour: {$max: '$hourBeginning'}}}])
  Future<Date> lastDayInserted() async {

    List pipeline = [];
    var group = {
      '\$group': {
        '_id': null,
        'last': {'\$max': '\$date'}
      }
    };
    pipeline.add(group);

    Map v = await config.coll.aggregate(pipeline);
    Map aux = v['result'].first;
    return Date.parse(aux['last']);
  }


  /// Recreate the collection from scratch.
  setup() async {
    if (!new Directory(config.DIR).existsSync()) new Directory(config.DIR)
        .createSync(recursive: true);
    /// check that the credentials are set

    await oneDayDownload(new Date(2014, 1, 1));

    await db.open();
    List<String> collections = await db.getCollectionNames();
    print('Collections in db:');
    print(collections);
    if (collections.contains(config.collectionName)) await config.coll.drop();
    await oneDayMongoInsert(new Date(2014, 1, 1));

    // this indexing assures that I don't insert the same data twice
    await db.createIndex(config.collectionName,
        keys: {'hourBeginning': 1, 'Constraint Name': 1, 'Contingency Name': 1, 'market': 1}, unique: true);
    await db.createIndex(config.collectionName, keys: {'Constraint Name': 1, 'market': 1});
    await db.createIndex(config.collectionName, keys: {'date': 1, 'market': 1});

    await db.close();
  }

  /// Bring the table up to date.
  updateDb(Date start, Date end) async {
    // TODO: make start/end dependent on the data.
    await db.open();
    Date day = start;
    while (!end.isBefore(day)) {
      await oneDayDownload(day);
      await oneDayMongoInsert(day);
      day = day.next;
    }
    await db.close();
  }
}




/// Remove all the data for a given day (in case the insert fails midway)
//  removeDataForDay(Date date) async {
//    SelectorBuilder sb = where;
//
//    TZDateTime start =
//        new TZDateTime(location, date.year, date.month, date.day).toUtc();
//    sb = sb.gte('hourBeginning', start);
//
//    Date next = date.next;
//    TZDateTime end =
//        new TZDateTime(location, next.year, next.month, next.day).toUtc();
//    sb = sb.lt('hourBeginning', end);
//
//    await coll.remove(sb);
//  }
