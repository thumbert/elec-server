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

/// A job to check if ISONE released a new ptid file.
///
/// If yes, update DuckDB send an email to the user with the new nodes that
/// were added and the nodes that were deactivated.
///
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
    newNodes.sort((a, b) => a.ptid.compareTo(b.ptid));
    logger.info('Found ${newNodes.length} new nodes activated on $activatedOn');
    if (newNodes.isNotEmpty) {
      content += '<h3>New nodes activated on $activatedOn</h3>';
      content += '<table cellpadding="5" style="border-collapse:collapse">';
      content +=
          '<tr style="background-color:#4472C4;color:white;border-bottom:2px solid #2F528F"><th>ptid</th><th>name</th><th>substation_name</th><th>unit_name</th><th>unit_short_name</th><th>zone_id</th><th>reserve_id</th><th>rsp_area</th><th>dispatch_zone</th></tr>';
      for (var i = 0; i < newNodes.length; i++) {
        final record = newNodes[i];
        final bg = i.isEven ? '' : 'background-color:#F2F2F2;';
        content +=
            '<tr style="$bg"><td>${record.ptid}</td><td>${record.name}</td><td>${record.substationName ?? ''}</td><td>${record.unitName ?? ''}</td><td>${record.unitShortName ?? ''}</td><td>${record.zoneId ?? ''}</td><td>${record.reserveId ?? ''}</td><td>${record.rspArea ?? ''}</td><td>${record.dispatchZone ?? ''}</td></tr>';
      }
      content += '</table>';
    }

    // get the nodes that were deactivated in this file
    final deactivatedOn = activatedOn;
    final deactivatedNodes = await getPtidsDeactivatedOn(deactivatedOn);
    deactivatedNodes.sort((a, b) => a.ptid.compareTo(b.ptid));
    logger.info(
        'Found ${deactivatedNodes.length} nodes deactivated on $deactivatedOn');
    if (deactivatedNodes.isNotEmpty) {
      content += '<h3>Nodes deactivated on $deactivatedOn</h3>';
      content += '<table cellpadding="5" style="border-collapse:collapse">';
      content +=
          '<tr style="background-color:#4472C4;color:white;border-bottom:2px solid #2F528F"><th>ptid</th><th>name</th><th>substation_name</th><th>unit_name</th><th>unit_short_name</th><th>zone_id</th><th>reserve_id</th><th>rsp_area</th><th>dispatch_zone</th></tr>';
      for (var i = 0; i < deactivatedNodes.length; i++) {
        final record = deactivatedNodes[i];
        final bg = i.isEven ? '' : 'background-color:#F2F2F2;';
        content +=
            '<tr style="$bg"><td>${record.ptid}</td><td>${record.name}</td><td>${record.substationName ?? ''}</td><td>${record.unitName ?? ''}</td><td>${record.unitShortName ?? ''}</td><td>${record.zoneId ?? ''}</td><td>${record.reserveId ?? ''}</td><td>${record.rspArea ?? ''}</td><td>${record.dispatchZone ?? ''}</td></tr>';
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
