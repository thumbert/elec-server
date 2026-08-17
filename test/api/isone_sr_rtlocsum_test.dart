import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';

Future<void> SrRtLocSumTest(Db db) async {
  // var api = SrRtLocSum(db);
  test('get testing data', () async {
    await db.open();
//    var data = await api('0', 401, 'Real Time Load Obligation',
//        '2015-06-01', '2015-06-01');
//    print(data);
    //expect(data.length, 2);
    await db.close();
  });
}

Future<void> main() async {
  await initializeTimeZone();
  Db db = Db('mongodb://localhost/mis');
  await SrRtLocSumTest(db);
}
