import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:puppeteer/puppeteer.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/client/isone/ptid_table.dart' as ptid_client;

class PtidArchive {
  PtidArchive({
    ComponentConfig? config,
    String? dir,
    required this.duckdbPath,
  }) {
    this.config = config ??
        ComponentConfig(
            host: '127.0.0.1', dbName: 'isone', collectionName: 'pnode_table');
    this.dir = dir ??
        '${Platform.environment['HOME']!}/Downloads/Archive/PnodeTable/Raw/';
  }

  late ComponentConfig config;
  late String dir;
  String duckdbPath;
  Db get db => config.db;
  final logger = Logger('PtidArchive');

  /// Insert one xlsx file into the collection.
  /// [file] points to the downloaded xlsx file.  NOTE that you have to convert
  /// the file to xlsx by hand (for now).
  Future insertMongo(File file) {
    var data = readXlsx(file);
    return config.coll
        .insertAll(data)
        .then(
            (_) => print('--->  SUCCESS inserting ${path.basename(file.path)}'))
        .catchError((e) => print('   $e'));
  }

  String toCsv(List<ptid_client.Record> records) {
    // wrap nullable string fields in quotes to handle embedded commas
    String q(Object? v) =>
        v == null ? '' : '"${v.toString().replaceAll('"', '""')}"';
    var csv = StringBuffer();
    csv.write(
        'node_type,ptid,name,substation_name,unit_name,unit_short_name,zone_id,reserve_id,rsp_area,dispatch_zone,dr_reserve_aggregation_zone_id,activated_on,deactivated_on\n');
    for (var record in records) {
      csv.write(
          '${record.nodeType},${record.ptid},${q(record.name)},${q(record.substationName)},${q(record.unitName)},${q(record.unitShortName)},${record.zoneId},${record.reserveId},${q(record.rspArea)},${q(record.dispatchZone)},${record.drReserveAggregationZoneId},${record.activatedOn},${record.deactivatedOn}\n');
    }
    return csv.toString();
  }

  /// Insert the records into DuckDB.  If a record already exists, it will not be inserted.
  /// If a record is no longer in the new data, it will be marked as deactivated with the
  /// activated_on date of the new data.
  ///
  void insertDuckDb(List<ptid_client.Record> records) {
    File(path.join(dir, 'pnode_table.csv')).writeAsStringSync(toCsv(records));
    final sql = '''
CREATE TEMPORARY TABLE tmp
AS (
    SELECT *
    FROM read_csv('${path.join(dir, 'pnode_table.csv')}', 
        header = true, nullstr = 'null')
);
INSERT INTO ptid_table
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM ptid_table d
        WHERE
            d.ptid = t.ptid
    )
);
-- set the deactivated_on date for the nodes that are no longer in the tmp table
UPDATE ptid_table d
SET deactivated_on = (SELECT MIN(activated_on) FROM tmp)
WHERE NOT EXISTS (
    SELECT *
    FROM tmp t
    WHERE t.ptid = d.ptid
)
AND d.node_type = 'node'
AND d.deactivated_on IS NULL;
''';
    var res = Process.runSync('duckdb', ['-c', sql, duckdbPath]);
    if (res.exitCode != 0) {
      throw 'DuckDB error: ${res.stderr}';
    }
  }

  ///
  List<ptid_client.Record> readSheetNodes(File file) {
    var filename = path.basename(file.path);
    if (path.extension(filename).toLowerCase() != '.xlsx') {
      throw 'Filename needs to be in the xlsx format';
    }
    final res = <ptid_client.Record>[];

    final asOfDate = Date.fromIsoString(getAsOfDate(filename));
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);

    /// Second tab
    /// rows 26:end are simple nodes
    var table = decoder.tables['New England']!;
    var nRows = table.rows.length;
    for (var r = 2; r < nRows; r++) {
      // sometimes the spreadsheet has empty rows
      if (table.rows[r][5] != null) {
        final one = ptid_client.Record(
          nodeType: ptid_client.NodeType.node,
          ptid: table.rows[r][5],
          name: table.rows[r][4],
          substationName: table.rows[r][1],
          unitName: table.rows[r][2],
          unitShortName: table.rows[r][3],
          zoneId: table.rows[r][6],
          reserveId: table.rows[r][7],
          rspArea: table.rows[r][8],
          dispatchZone: table.rows[r][9],
          drReserveAggregationZoneId: null,
          activatedOn: asOfDate,
          deactivatedOn: null,
        );

        res.add(one);
      }
    }
    return res;
  }

  /// Read an XLSX file.  Note that ISO files are xls, so you will need to
  /// convert it by hand for now.
  /// filename should look like this: 'pnode_table_2017_08_03.xlsx'
  @Deprecated('Use readXlsx2 instead')
  List<Map<String, dynamic>> readXlsx(File file, {String? asOfDate}) {
    var filename = path.basename(file.path);
    if (path.extension(filename).toLowerCase() != '.xlsx') {
      throw 'Filename needs to be in the xlsx format';
    }

    asOfDate ??= getAsOfDate(filename);

    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    List<Map<String, Object?>> res;

    if (Date.parse(asOfDate).isBefore(Date.utc(2018, 6, 7))) {
      res = _readXlsxVersion1(decoder);
    } else {
      /// current format
      res = _readXlsxVersion2(decoder);
    }

    /// add the asOfDate (as a String) to all rows
    return res.map((e) {
      e['asOfDate'] = asOfDate;
      return e;
    }).toList();
  }

  /// prior to 2018-06-07 the spreadsheet had only one sheet
  List<Map<String, Object?>> _readXlsxVersion1(SpreadsheetDecoder decoder) {
    var res = <Map<String, Object?>>[];
    var table = decoder.tables['New England']!;

    /// the 2rd row is the Hub
    res.add({
      'ptid': 4000,
      'name': table.rows[2][2],
      'spokenName': 'HUB',
      'type': 'hub'
    });

    /// rows 4:11 are the Zones
    for (var r = 4; r < 12; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
        'type': 'zone'
      });
    }

    /// rows 13:16 are Reserve Zones
    for (var r = 13; r < 17; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][0],
        'type': 'reserve zone',
      });
    }

    /// rows 18:23 are Interfaces
    for (var r = 18; r < 24; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
      });
    }

    /// rows 26:end are simple nodes
    var nRows = table.rows.length;
    for (var r = 26; r < nRows; r++) {
      // sometimes the spreadsheet has empty rows
      if (table.rows[r][5] != null) {
        var aux = {
          'ptid': table.rows[r][5],
          'name': table.rows[r][4],
          'spokenName': table.rows[r][0],
          'zonePtid': table.rows[r][6],
          'reservePtid': table.rows[r][7],
          'rspArea': table.rows[r][8],
          'dispatchZone': table.rows[r][9],
        };
        if (table.rows[r][2] != null) aux['unitName'] = table.rows[r][2];
        if (table.rows[r][3] != null) aux['unitShortName'] = table.rows[r][3];
        res.add(aux);
      }
    }
    return res;
  }

  /// after 2018-06-07 the format changed to 2 sheets
  List<Map<String, Object?>> _readXlsxVersion2(SpreadsheetDecoder decoder) {
    var res = <Map<String, Object?>>[];
    var table = decoder.tables['Zone Information']!;

    /// the 2rd row is the Hub
    res.add({
      'ptid': 4000,
      'name': table.rows[2][2],
      'spokenName': 'HUB',
      'type': 'hub'
    });

    /// rows 5:12 are the Zones
    for (var r = 5; r < 13; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
        'type': 'zone'
      });
    }

    /// rows 15:18 are Reserve Zones
    for (var r = 15; r < 19; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][0],
        'type': 'reserve zone',
      });
    }

    /// Format changed in 2025-11 with the introduction of NECEC interface.
    /// rows 21:26 are Interfaces
    var lastRow = table.rows.indexWhere((e) => e[0] == 'ISO-NE PUBLIC');
    for (var r = 21; r < lastRow; r++) {
      res.add({
        'ptid': table.rows[r][3],
        'name': table.rows[r][2],
        'spokenName': table.rows[r][0],
      });
    }

    /// rows 8:26 are the DRR aggregation zones
    for (var r = 7; r < lastRow; r++) {
      if (table.rows[r][7] == null) continue;
      res.add({
        'ptid': table.rows[r][7],
        'name': table.rows[r][6],
        'spokenName': table.rows[r][5],
        'type': 'demand response zone'
      });
    }

    /// Second tab
    /// rows 26:end are simple nodes
    table = decoder.tables['New England']!;
    var nRows = table.rows.length;
    for (var r = 2; r < nRows; r++) {
      // sometimes the spreadsheet has empty rows
      if (table.rows[r][5] != null) {
        var aux = {
          'ptid': table.rows[r][5],
          'name': table.rows[r][4],
          'spokenName': table.rows[r][0],
          'substationName': table.rows[r][1],
          'zonePtid': table.rows[r][6],
          'reservePtid': table.rows[r][7],
          'rspArea': table.rows[r][8],
          'dispatchZone': table.rows[r][9],
        };
        if (table.rows[r][2] != null) aux['unitName'] = table.rows[r][2];
        if (table.rows[r][3] != null) aux['unitShortName'] = table.rows[r][3];
        res.add(aux);
      }
    }
    return res;
  }

  /// Return the asOfDate in the yyyy-mm-dd format from the filename.
  /// Filename is usually just the basename, and in the form: 'pnode_table_2017_08_03.xlsx'
  String getAsOfDate(String filename) {
    var regExp = RegExp(r'pnode_table_(\d{4})_(\d{2})_(\d{2})\.xlsx');
    var matches = regExp.allMatches(filename);
    var match = matches.elementAt(0);
    if (match.groupCount != 3) {
      throw 'Can\'t parse the date from filename: $filename';
    }
    return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
  }

  /// Get all the links with the xlsx files from the ISONE website.
  Future<List<String>> getLinks() async {
    final browser = await puppeteer.launch(
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    );
    late final List<String> links;
    try {
      final page = await browser.newPage();
      await page.goto(
        'https://www.iso-ne.com/markets-operations/settlements/pricing-node-tables',
        wait: Until.networkIdle,
      );

      // Wait for the document library to render its links
      await page.waitForSelector('a[href*=".xlsx"]',
          timeout: Duration(seconds: 30));

      links = (await page.evaluate<List>('''() => {
      return Array.from(document.querySelectorAll('a[href]'))
        .map(a => a.href)
        .filter(h => h.toLowerCase().includes('.xlsx'));
    }''')).cast<String>();
    } catch (e) {
      print('Error while extracting links: $e');
      rethrow;
    } finally {
      await browser.close();
    }
    return links;
  }

  /// Download a ptid file from the ISO.  Save it with the same name.
  Future downloadFile(String url) async {
    var filename = path.basename(url);
    var fileout = File(dir + filename);

    if (fileout.existsSync()) {
      print('File $filename is already downloaded.');
    }

    return HttpClient()
        .getUrl(Uri.parse(url))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.pipe(fileout.openWrite()));
  }

  /// Recreate the duckdb archive from scratch.
  void setupDb2() {
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    final sql = '''
SET VARIABLE created_on = DATE '1999-01-01';
CREATE TABLE IF NOT EXISTS ptid_table (
    node_type ENUM('hub', 'node', 'load_zone', 'aggregation_zone', 'reserve_zone', 'interface') NOT NULL,
    ptid INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    substation_name VARCHAR,
    unit_name VARCHAR,
    unit_short_name VARCHAR,
    zone_id INTEGER,
    reserve_id INTEGER,
    rsp_area VARCHAR,
    dispatch_zone VARCHAR,
    dr_reserve_aggregation_zone_id INTEGER,
    activated_on DATE NOT NULL,
    deactivated_on DATE
);

INSERT INTO ptid_table
   VALUES 
    ('hub', 4000, '.H.INTERNAL_HUB', 'HUB', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4001, '.Z.MAINE', 'ME', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4002, '.Z.NEWHAMPSHIRE', 'NH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4003, '.Z.VERMONT', 'VT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4004, '.Z.CONNECTICUT', 'CT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4005, '.Z.RHODEISLAND', 'RI', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4006, '.Z.SEMASS', 'SEMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4007, '.Z.WCMASS', 'WCMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4008, '.Z.NEMASSBOST', 'NEMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ---
    ('reserve_zone', 7000, 'REST OF SYSTEM', 'ROS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('reserve_zone', 7001, 'SOUTH WEST CONNECTICUT', 'SWCT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('reserve_zone', 7002, 'CONNECTICUT', 'CT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('reserve_zone', 7003, 'NEMASSBOST', 'NEMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ---
    ('interface', 4010, '.I.SALBRYNB345 1', 'NB', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4011, '.I.ROSETON 345 1', 'ROSETON', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4012, '.I.HQ_P1_P2345 5', 'PHASE 2', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4013, '.I.HQHIGATE120 2', 'HIGHGATE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4014, '.I.SHOREHAM138 99', 'CROSS SOUND CABLE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4015, '.I.NRTHPORT138 5', '1385 CABLE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4016, '.I.HQMRL_RD345 1', 'NECEC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ---
    ('aggregation_zone', 7600, 'DR.CT_Eastern', 'ECT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7601, 'DR.CT_Northern', 'NCT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7602, 'DR.CT_Norwalk-Stamford', 'NRST', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7603, 'DR.CT_Western_SWCT', 'SWCT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7604, 'DR.CT_Western', 'WCT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7605, 'DR.ME_Bangor_Hydro', 'BNGR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7606, 'DR.ME_Maine', 'ME', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7607, 'DR.ME_Portland', 'PORT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7608, 'DR.MA_Boston', 'BSTN', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7609, 'DR.MA_North_Shore', 'NSHR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7610, 'DR.NH_New_Hampshire', 'NEWH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7611, 'DR.NH_Seacoast', 'SEAC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7612, 'DR.MA_Lower_SEMA', 'LSMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7613, 'DR.MA_SEMA', 'SEMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7614, 'DR.VT_Northwest_Vermont', 'NWVT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7615, 'DR.VT_Vermont', 'VT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7616, 'DR.MA_Central', 'CTMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7617, 'DR.MA_Springfield', 'SFLD', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7618, 'DR.MA_Western', 'WMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7619, 'DR.RI_Rhode_Island', 'RI', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
;
''';
    var res = Process.runSync('duckdb', ['-c', sql, duckdbPath]);
    if (res.exitCode != 0) {
      throw 'DuckDB error: ${res.stderr}';
    }

    // get all the files staring with 2026-05-20
    var files = Directory(dir)
        .listSync()
        .where((f) => path.extension(f.path).toLowerCase() == '.xlsx')
        .where((f) => path.basename(f.path).startsWith('pnode_table_'))
        .where((f) =>
            getAsOfDate(path.basename(f.path)).compareTo('2025-05-20') >= 0)
        .toList();
    files.sort((a, b) => getAsOfDate(path.basename(a.path))
        .compareTo(getAsOfDate(path.basename(b.path))));
    for (var file in files) {
      logger.info('Inserting ${path.basename(file.path)} into DuckDB');
      var data = readSheetNodes(File(file.path));
      insertDuckDb(data);
    }
  }

  /// Recreate the collection from scratch.
  /// Insert all the files in the archive directory.
  @Deprecated('Use setupDb2 instead')
  Future<void> setupDb() async {
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    // var fname = 'pnode_table_2017_08_03.xls';
    // var url = 'https://www.iso-ne.com/static-assets/documents/2017/08/$fname';
    //await downloadFile(url);

    await config.db.open();
    var collections = await config.db.getCollectionNames();
    print('Collections in db:');
    print(collections);
    if (collections.contains(config.collectionName)) await config.coll.drop();

    // insert all xlsx files in the Raw/ directory
//    Directory directory = new Directory(dir);
//    var files = directory.listSync().where((f) => path.extension(f.path).toLowerCase() == '.xlsx').toList();
//    for (var file in files) {
//      await insertMongo(file);
//    }

    // this indexing assures that I don't insert the same data twice
    await config.db.createIndex(config.collectionName,
        keys: {'asOfDate': 1, 'ptid': 1}, unique: true);
    await config.db.createIndex(config.collectionName, keys: {'asOfDate': 1});
    await config.db.close();
  }
}
