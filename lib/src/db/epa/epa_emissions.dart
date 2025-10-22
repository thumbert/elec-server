import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:http/http.dart';
import 'package:path/path.dart';

class EpaEmissionsArchive {
  /// EPA hourly emissions archive
  EpaEmissionsArchive({required this.dir});

  final String dir;
  final String apiUrlBase = 'https://api.epa.gov/easey';
  // S3 bucket url base + s3Path (in get request) = the full path to the files
  final String bucketUrlBase = 'https://api.epa.gov/easey/bulk-files';

  /// Get all the files.
  /// This is a long query, takes 2 minutes
  ///
  Future<List<Map<String, dynamic>>> getBulkFiles() async {
    final key = dotenv.env['EIA_API_KEY']!;
    final url = '$apiUrlBase/camd-services/bulk-files?API_KEY=$key';
    print(url);
    var res = await get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw StateError("Download failed! ${res.body}");
    }
    var data = json.decode(res.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<int> getFile(String state, int year) async {
    state = state.toLowerCase();
    final url =
        '$bucketUrlBase/emissions/hourly/state/emissions-hourly-$year-$state.csv';
    final dirOut = Directory('$dir/${state.toUpperCase()}');
    if (!dirOut.existsSync()) {
      dirOut.createSync(recursive: true);
    }
    final fileOut = '${dirOut.path}/emissions-hourly-$year-$state.csv';
    // print(url);

    // download the file and save it to file
    var resD = await get(Uri.parse(url));
    if (resD.statusCode != 200) {
      throw StateError("Download failed! ${resD.body}");
    }
    File(fileOut).writeAsStringSync(resD.body);
    print('Downloaded ${state.toUpperCase()} file for $year');

    // gzip it!
    var res =
        Process.runSync('gzip', ['-f', fileOut], workingDirectory: dirOut.path);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(fileOut)} has failed');
    }
    print('Gzipped file ${basename(fileOut)}');

    return 0;
  }

  // @override
  // String getUrl(String state, int year) =>
  //     'https://webservices.iso-ne.com/api/v1.1/hbregulationoffer/day/${yyyymmdd(asOfDate)}';
}
