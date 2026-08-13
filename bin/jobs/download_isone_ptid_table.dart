import 'dart:io';

import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/isone/ptid_table.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/utils/mailtrap.dart';
import 'package:logging/logging.dart';

bool fileDownloadedToday(File file) {
  final today = DateTime.now();
  if (file.existsSync()) {
    final stat = file.statSync();
    final modified = stat.modified;
    if (modified.year == today.year &&
        modified.month == today.month &&
        modified.day == today.day) {
      return true;
    }
  }
  return false;
}

/// Extract all xlsx download links from the ISO-NE pricing-node-tables page.
Future<void> main(List<String> args) async {
  final logger = Logger('download isone ptid table');
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  logger.info('Starting ${DateTime.now()}');
  dotenv.load('.env/prod.env');

  // download latest files
  logger.info('Checking if ISO released a new ptid file...');
  final archive = getIsonePtidArchive();
  final links = await archive.getLinks();
  for (final link in links.take(10)) {
    final filename = link.split('/').last;
    final fileout = File('${archive.dir}/$filename');
    if (!fileout.existsSync()) {
      logger.info('    Downloading $link...');
      await archive.downloadFile(link);
    }
  }
  logger.info('Done');

  // check if the last ISO file was downloaded today
  final link = links.first;
  final filename = link.split('/').last;
  final fileout = File('${archive.dir}/$filename');
  var content = '';
  if (fileDownloadedToday(fileout)) {
    logger.info('Inserting $filename into DuckDB...');
    var records = archive.readSheetNodes(fileout);
    archive.insertDuckDb(records);
    logger.info('Done');

    // get the new nodes that were added in this file
    final activatedOn = Date.parse(archive.getAsOfDate(fileout.path));
    final newNodes = await getPtidsActivatedOn(activatedOn);
    if (newNodes.isNotEmpty) {
      content += '<h3>New nodes activated on: $activatedOn</h3>';
      content += '<table border="1" cellpadding="5">';
      content +=
          '<tr><th>ptid</th><th>name</th><th>substation_name</th><th>unit_name</th><th>unit_short_name</th><th>zone_id</th><th>reserve_id</th><th>rsp_area</th><th>dispatch_zone</th><th>dr_reserve_aggregation_zone_id</th></tr>';
      for (final record in newNodes) {
        content +=
            '<tr><td>${record.ptid}</td><td>${record.name}</td><td>${record.substationName ?? ''}</td><td>${record.unitName ?? ''}</td><td>${record.unitShortName ?? ''}</td><td>${record.zoneId ?? ''}</td><td>${record.reserveId ?? ''}</td><td>${record.rspArea ?? ''}</td><td>${record.dispatchZone ?? ''}</td><td>${record.drReserveAggregationZoneId ?? ''}</td></tr>';
      }
      content += '</table>';
    }

    // get the nodes that were deactivated in this file
    final deactivatedOn = activatedOn;
    final deactivatedNodes = await getPtidsDeactivatedOn(deactivatedOn);
    if (deactivatedNodes.isNotEmpty) {
      content += '<h3>Nodes deactivated on: $deactivatedOn</h3>';
      content += '<table border="1" cellpadding="5">';
      content +=
          '<tr><th>ptid</th><th>name</th><th>substation_name</th><th>unit_name</th><th>unit_short_name</th><th>zone_id</th><th>reserve_id</th><th>rsp_area</th><th>dispatch_zone</th><th>dr_reserve_aggregation_zone_id</th></tr>';
      for (final record in deactivatedNodes) {
        content +=
            '<tr><td>${record.ptid}</td><td>${record.name}</td><td>${record.substationName ?? ''}</td><td>${record.unitName ?? ''}</td><td>${record.unitShortName ?? ''}</td><td>${record.zoneId ?? ''}</td><td>${record.reserveId ?? ''}</td><td>${record.rspArea ?? ''}</td><td>${record.dispatchZone ?? ''}</td><td>${record.drReserveAggregationZoneId ?? ''}</td></tr>';
      }
      content += '</table>';
    }
  }

  if (content.isNotEmpty) {
    logger.info('Sending email...');
    var res = await sendEmail(
      subject: 'New ISONE ptid table downloaded!',
      body: content,
      to: [
        // Email(dotenv.env['EMAIL_WORK']!),
        Email(dotenv.env['EMAIL_TO']!),
      ],
      from: Email(dotenv.env['EMAIL_FROM']!),
      isHtml: true,
    );
    if (res.statusCode != 200 && res.statusCode != 202) {
      logger.warning('Error sending email: ${res.statusCode} ${res.body}');
    }
    logger.info('Email sent with status code: ${res.statusCode}');
  }

  logger.info('Done at ${DateTime.now()}');
  exit(0);
}
