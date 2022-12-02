library test.utilities.rate_board_test;

import 'package:elec_server/src/db/utilities/eversource/rate_board.dart';

Future<void> tests() async {
  var archive = RateBoardArchive();

  var res = await archive.getCurrentRates();
  print(res);
}

Future<void> main() async {
  await tests();
}