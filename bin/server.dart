
import 'dart:io';

//import 'package:logging/logging.dart';
//import 'package:logging_handlers/server_logging_handlers.dart';
import 'package:rpc/rpc.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';

import 'package:elec_server/api/api_isone_dalmp.dart';
import 'package:elec_server/api/api_isone_rtlmp.dart';
import 'package:elec_server/api/api_isone_bindingconstraints.dart';
import 'package:elec_server/api/api_isone_energyoffers.dart';
import 'package:elec_server/api/api_isone_demandbids.dart';
import 'package:elec_server/api/api_isone_ptids.dart';
import 'package:elec_server/api/utilities/api_customer_counts.dart';
import 'package:elec_server/api/utilities/api_customer_counts_eversource.dart' as eversource;
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec_server/api/api_system_demand.dart';
import 'package:elec_server/api/api_isone_zonal_demand.dart';

const String _API_PREFIX = '';
final ApiServer _apiServer = new ApiServer(apiPrefix: _API_PREFIX, prettyPrint: true);
const String host = '127.0.0.1';


registerApis() async {

  Db db2 = new Db('mongodb://$host/isone');
  await db2.open();
  _apiServer.addApi( new ApiPtids(db2) );
//  _apiServer.addApi( new ApiCustomerCounts(db2) );

  Db db3 = new Db('mongodb://$host/isoexpress');
  await db3.open();
  _apiServer.addApi( new DaLmp(db3) );
//  _apiServer.addApi( new RtLmp(db3) );
//  _apiServer.addApi( new BindingConstraints(db3) );
//  _apiServer.addApi( new DaEnergyOffers(db3) );
//  _apiServer.addApi( new DaDemandBids(db3) );
//  _apiServer.addApi( new SystemDemand(db3) );
//  _apiServer.addApi( new ZonalDemand(db3) );
//
//  Db db4 = new Db('mongodb://$host/eversource');
//  await db4.open();
//  _apiServer.addApi( new eversource.ApiCustomerCounts(db4) );


//  var api = new ApiTemperatureNoaa();
//  await api.init();
//  _apiServer.addApi(api);
}

//class SyncFileLoggingHandler implements BaseLoggingHandler {
//
//  LogRecordTransformer transformer;
//  final String filename;
//  File _file;
//
//  SyncFileLoggingHandler(String this.filename, {this.transformer}) {
//    if (this.transformer == null) this.transformer = new StringTransformer();
//    _file = new File(filename);
//  }
//
//  call(LogRecord logRecord) {
//    var f = _file.openSync(mode:FileMode.APPEND);
//    f.writeStringSync(transformer.transform(logRecord) + "\n");
//    f.closeSync();
//  }
//}

main() async {
//  Logger.root.level = Level.SEVERE;
//  Logger.root.onRecord.listen(new SyncFileLoggingHandler('myLogFile.txt'));
//  if (stdout.hasTerminal)
//    Logger.root.onRecord.listen(new LogPrintHandler());

//  initializeTimeZone( getLocationTzdb() );
  await initializeTimeZone();

  await registerApis();

  _apiServer.enableDiscoveryApi();

  var port = 8080;  // production
  //var port = 8081;  // test
  HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  server.listen(_apiServer.httpRequestHandler);
}



