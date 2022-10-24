library lng.lib_stjohns;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:http/http.dart';
import 'package:more/more.dart';
import 'package:path/path.dart';

class StJohnsVessels {
  StJohnsVessels({String? dir}) {
    dir ??=
        '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Lng/StJohns/';
    _dir = dir;
    if (!Directory(_dir).existsSync()) {
      Directory(_dir).createSync(recursive: true);
    }
  }

  late String _dir;

  Future<List<Map<String, String>>> getCurrentVessels() async {
    var url = 'https://www.sjport.com/current_vessels.php';
    return _process(url);
  }

  Future<List<Map<String, String>>> getExpectedVessels() async {
    var url = 'https://www.sjport.com/expected_vessels.php';
    return _process(url);
  }

  Future<List<Map<String, String>>> _process(String url) async {
    var res = await get(Uri.parse(url));
    var out = [];
    if (res.statusCode == 200) {
      /// very strange, the response contains some crazy characters at the beginning.
      /// not sure if this will change in the future or not, but the first character
      /// should be '['
      var ind = res.body.indexOf('[');
      out = json.decode(res.body.skip(ind));
    } else {
      throw StateError('Website for StJohns port down, or url changed');
    }
    return out.map((e) => <String, String>{...e}).toList();
  }

  ///
  bool filterLngShips(Map<String, String> xs) {
    var res = false;
    var contents = (xs['CARGO_ACTIVITY'] as String).toLowerCase();
    if (contents.contains('lng') ||
        contents.contains('liquid') ||
        contents.contains('liquified') ||
        contents.contains('natural gas')) {
      res = true;
    }
    if (xs['VESSEL_NAME']?.toLowerCase() == 'bw gdf suez boston') {
      res = true;
    }
    return res;
  }

  File get archiveFile => File(join(_dir, 'expected_lng_ships.csv'));

  List<Ship> readArchiveFile() {
    if (!archiveFile.existsSync()) {
      /// create an empty csv file, if file doesn't exist yet
      var csv = const ListToCsvConverter().convert([
        [
          'VESSEL_NAME',
          'SHIP_LINE',
          'BERTH',
          'AGENT',
          'ETA',
          'CARGO_ACTIVITY',
        ]
      ]);
      archiveFile.writeAsStringSync(csv);
    }
    var aux =
        const CsvToListConverter().convert(archiveFile.readAsStringSync());
    var ships = aux
        .skip(1)
        .map((e) => Map<String, String>.fromIterables(
            aux.first.cast(), e.cast<String>()))
        .map((e) => Ship.fromMap(e))
        .toList();
    return ships;
  }

  /// Determine if this ship is new, that is it is not in the archive yet.
  bool isNewShip(Ship ship) {
    var existingShips = readArchiveFile();
    var recentShips = existingShips
        .where((e) => (e.eta.value - ship.eta.value).abs() <= 5)
        .where((e) => e.vesselName == ship.vesselName);
    // if there is no match, it's a new ship
    return recentShips.isEmpty;
  }

  /// Append this ship to the csv file archive
  void saveShipToArchive(Ship ship) {
    var csv = const ListToCsvConverter().convert([
      [
        ship.vesselName,
        ship.shipLine,
        ship.berth,
        ship.agent,
        ship.eta.toString(),
        ship.cargoActivity,
      ]
    ]);
    archiveFile.writeAsStringSync(csv, mode: FileMode.append);
  }
}

class Ship {
  Ship(
      {required this.vesselName,
      required this.shipLine,
      required this.berth,
      required this.agent,
      required this.eta,
      required this.cargoActivity});

  final String vesselName;
  final String shipLine;
  final String berth;
  final String agent;
  final Date eta;
  final String cargoActivity;

  static Ship fromMap(Map<String, String> xs) {
    return Ship(
        vesselName: xs['VESSEL_NAME']!,
        shipLine: xs['SHIP_LINE'] ?? 'NA',
        berth: xs['BERTH'] ?? 'NA',
        agent: xs['AGENT'] ?? 'NA',
        eta: Date.parse(xs['ETA']!),
        cargoActivity: xs['CARGO_ACTIVITY']!);
  }
}
