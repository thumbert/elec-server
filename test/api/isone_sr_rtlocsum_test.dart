library test.api.isone_sr_rtlocsum;


import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec_server/api/mis/api_sr_rtlocsum.dart';


SrRtLocSumTest(Db db) async {
  var api = new SrRtLocSum(db);
  test('get testing data', () async {
    await db.open();
//    var data = await api('0', 401, 'Real Time Load Obligation',
//        '2015-06-01', '2015-06-01');
//    print(data);
    //expect(data.length, 2);
    await db.close();
  });
}


main() async {
  initializeTimeZoneSync( getLocationTzdb() );
  Db db = new Db('mongodb://localhost/mis');
  await SrRtLocSumTest(db);

}
