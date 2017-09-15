// Copyright (c) 2017, adrian. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart';
import 'package:rpc/rpc.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';

import 'package:elec_server/api/isone_dalmp.dart';
import 'package:elec_server/api/isone_bindingconstraints.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

const String _API_PREFIX = '';
final ApiServer _apiServer = new ApiServer(apiPrefix: _API_PREFIX, prettyPrint: true);
const String host = '127.0.0.1';


registerApis() async {
  Db db = new Db('mongodb://$host/isone_dam');
  await db.open();
  DaLmp dalmp = new DaLmp(db);
  _apiServer.addApi(dalmp);

  Db db2 = new Db('mongodb://$host/isone');
  await db2.open();
  BindingConstraints bindingConstraints = new BindingConstraints(db2);
  _apiServer.addApi(bindingConstraints);


//  var api = new ApiTemperatureNoaa();
//  await api.init();
//  _apiServer.addApi(api);
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new SyncFileLoggingHandler('myLogFile.txt'));
  if (stdout.hasTerminal)
    Logger.root.onRecord.listen(new LogPrintHandler());

  initializeTimeZoneSync( getLocationTzdb() );

  await registerApis();

  _apiServer.enableDiscoveryApi();

  HttpServer server = await HttpServer.bind(InternetAddress.ANY_IP_V4, 8080);
  server.listen(_apiServer.httpRequestHandler);
}



