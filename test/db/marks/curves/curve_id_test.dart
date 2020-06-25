library test.db.curves.curve_id_test;

import 'package:elec_server/src/db/marks/curves/curve_id.dart';
import 'package:elec_server/src/db/marks/curves/json/curve_id_isone.dart' as isone;


void tests() async {

}

void insertData() async {
  var archive = CurveIdArchive();
  await archive.db.open();
  await archive.insertData(isone.getCurves());
  await archive.db.close();
}


void main() async {
  await insertData();
}