library test.client.other.marks_test;

import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

dbTests(String host) async {
  var db3 = Db('mongodb://$host/isoexpress');
  group('Marks archive tests:', () {
    setUp(() async => await db3.open());
    tearDown(() async => await db3.close());
    test('Insert one curve', () {
      var data = <String,dynamic>{
        'asOfDate': '2019-10-05',
        'curveId': 'testId',
        'months': ['2019-11', '2019-12', '2020-01', '2020-02'],

      };
    });
  });
}



main() async {
  var host = '127.0.0.1';
  await dbTests(host);

}