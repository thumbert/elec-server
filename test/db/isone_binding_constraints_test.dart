
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isone_binding_constraints.dart';

import 'package:mongo_dart/mongo_dart.dart';

setup() async {
  DaBindingConstraintArchive arch = new DaBindingConstraintArchive();
//  await arch.oneDayDownload(new Date(2015,2,17));

//  var data = arch.oneDayRead(new Date(2014, 1, 1));
//  data.forEach(print);

  //await arch.setup();

  await arch.updateDb(new Date(2016,12,31), new Date(2017,08,31));
}

test_bc() async {
  DaBindingConstraintArchive arch = new DaBindingConstraintArchive();

  await arch.db.open();
  Date end = await arch.lastDayInserted();
  print('Last day inserted is: $end');
  await arch.db.close();
}

queryTest() async {

  Db db = new Db('mongodb://localhost/isone');
  await db.open();
  DbCollection coll = db.collection('binding_constraints');

  SelectorBuilder query = where;
  query = query.gte('date', '2017-01-01');
  query = query.lte('date', '2017-01-02');
  query = query.eq('market', 'DA');
  query = query.excludeFields(['_id', 'Hour Ending', 'date', 'market']);
  print(query);
  var res = await coll.find(query).toList();
  res.forEach(print);

  await db.close();
}


main() async {
  //await setup();

  //await test_bc();

  await queryTest();
}