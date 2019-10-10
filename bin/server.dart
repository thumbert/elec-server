
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
import 'package:elec_server/api/api_scc_report.dart';
import 'package:elec_server/api/utilities/api_customer_counts_ngrid.dart' as ngrid;
import 'package:elec_server/api/utilities/api_customer_counts_eversource.dart' as eversource;
import 'package:elec_server/api/utilities/api_competitive_suppliers_eversource.dart' as eversourcecs;
import 'package:elec_server/api/utilities/api_load_eversource.dart' as eversourceLoad;
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec_server/api/api_system_demand.dart';
import 'package:elec_server/api/api_isone_zonal_demand.dart';


const String _API_PREFIX = '';
final ApiServer _apiServer = new ApiServer(apiPrefix: _API_PREFIX, prettyPrint: true);
const String host = '127.0.0.1';


registerApis() async {

//  Db db2 = new Db('mongodb://$host/isone');
//  await db2.open();
//  _apiServer.addApi(ApiPtids(db2));
//  _apiServer.addApi( new ngrid.ApiCustomerCounts(db2) );

  var db3 = Db('mongodb://$host/isoexpress');
  await db3.open();
  _apiServer.addApi(DaLmp(db3) );
//  _apiServer.addApi(BindingConstraints(db3) );
  _apiServer.addApi(DaEnergyOffers(db3) );
//  _apiServer.addApi(SccReport(db3) );
//  _apiServer.addApi(DaDemandBids(db3) );
//  _apiServer.addApi(SystemDemand(db3) );
//
//  var db4 = Db('mongodb://$host/eversource');
//  await db4.open();
//  _apiServer.addApi( eversource.ApiCustomerCounts(db4) );
//  _apiServer.addApi( eversourceLoad.ApiLoadEversource(db4) );
//
//  var db5 = Db('mongodb://$host/utility');
//  await db5.open();
//  _apiServer.addApi( eversourcecs.ApiCompetitiveCustomerCountsCt(db5) );


}


main() async {
  await initializeTimeZone();

  await registerApis();

  _apiServer.enableDiscoveryApi();

  var port = 8080;  // production
  //var port = 8081;  // test
  HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  server.listen(_apiServer.httpRequestHandler);
}



