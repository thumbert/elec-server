
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart';
import 'package:rpc/rpc.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';

import 'package:elec_server/api/isone_dalmp.dart';
import 'package:elec_server/api/isone_bindingconstraints.dart';
import 'package:elec_server/api/api_isone_ptids.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

const String _API_PREFIX = '';
final ApiServer _apiServer = new ApiServer(apiPrefix: _API_PREFIX, prettyPrint: true);
const String host = '127.0.0.1';


registerApis() async {
  Db db = new Db('mongodb://$host/isone_dam');
  await db.open();
  _apiServer.addApi( new DaLmp(db) );

  Db db2 = new Db('mongodb://$host/isone');
  await db2.open();
  _apiServer.addApi( new BindingConstraints(db2) );
  _apiServer.addApi( new ApiPtids(db2) );


//  var api = new ApiTemperatureNoaa();
//  await api.init();
//  _apiServer.addApi(api);
}

main() async {
  Logger.root.level = Level.SEVERE;
  Logger.root.onRecord.listen(new SyncFileLoggingHandler('myLogFile.txt'));
  if (stdout.hasTerminal)
    Logger.root.onRecord.listen(new LogPrintHandler());

  initializeTimeZoneSync( getLocationTzdb() );

  await registerApis();

  _apiServer.enableDiscoveryApi();

  HttpServer server = await HttpServer.bind(InternetAddress.ANY_IP_V4, 8080);
  server.listen(_apiServer.httpRequestHandler);
}



