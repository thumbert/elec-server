import 'package:logging/logging.dart';
import 'package:elec_server/src/db/config.dart';

class NyisoPtidArchive {
  NyisoPtidArchive({ComponentConfig? config, String? dir}) {
  }

  final logger = Logger('NyisoPtidArchive');


  static final zoneNameToPtid = <String, int>{
    'CAPITL': 61757,
    'CENTRL': 61754,
    'DUNWOD': 61760,
    'GENESE': 61753,
    'H Q': 61844,
    'HUD VL': 61758,
    'LONGIL': 61762,
    'MHK VL': 61756,
    'MILLWD': 61759,
    'N.Y.C.': 61761,
    'NORTH': 61755,
    'NPX': 61845,
    'O H': 61846,
    'PJM': 61847,
    'WEST': 61752,
  };

  static final zonePtidToSpokenName = <int, String>{
    61752: 'Zone A',
    61753: 'Zone B',
    61754: 'Zone C',
    61755: 'Zone D',
    61756: 'Zone E',
    61757: 'Zone F',
    61758: 'Zone G',
    61759: 'Zone H',
    61760: 'Zone I',
    61761: 'Zone J',
    61762: 'Zone K',
  };
}
