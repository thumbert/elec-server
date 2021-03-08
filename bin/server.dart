import 'dart:io';

import 'package:elec_server/api/isoexpress/api_isone_regulation_requirement.dart';
import 'package:elec_server/api/isoexpress/api_wholesale_load_cost.dart';
import 'package:elec_server/api/marks/curves/curve_ids.dart';
import 'package:elec_server/api/marks/forward_marks.dart';
import 'package:elec_server/api/risk_system/api_calculator.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:logging/logging.dart';
import 'package:rpc/rpc.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:timezone/standalone.dart';

import 'package:elec_server/api/isoexpress/api_isone_dalmp.dart';
import 'package:elec_server/api/isoexpress/api_isone_rtlmp.dart';
import 'package:elec_server/api/isoexpress/api_isone_bindingconstraints.dart';
import 'package:elec_server/api/isoexpress/api_isone_energyoffers.dart';
import 'package:elec_server/api/isoexpress/api_isone_demandbids.dart';
import 'package:elec_server/api/api_isone_ptids.dart';
import 'package:elec_server/api/api_scc_report.dart';
import 'package:elec_server/api/utilities/api_customer_counts_ngrid.dart'
    as ngrid;
import 'package:elec_server/api/utilities/api_customer_counts_eversource.dart'
    as eversource;
import 'package:elec_server/api/utilities/api_competitive_suppliers_eversource.dart'
    as eversourcecs;
import 'package:elec_server/api/utilities/api_load_eversource.dart'
    as eversourceLoad;
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec_server/api/isoexpress/api_system_demand.dart';
import 'package:elec_server/api/isoexpress/api_isone_zonal_demand.dart';
import 'package:elec_server/src/utils/cors_middleware.dart';

const String _API_PREFIX = '';
final ApiServer _apiServer =
    ApiServer(apiPrefix: _API_PREFIX, prettyPrint: true);
const String host = '127.0.0.1';

void registerApis() async {
  await DbProd.isone.open();
  _apiServer.addApi(ApiPtids(DbProd.isone));
//  _apiServer.addApi( new ngrid.ApiCustomerCounts(db2) );

  await DbProd.isoexpress.open();
  _apiServer.addApi(DaLmp(DbProd.isoexpress));
  _apiServer.addApi(BindingConstraints(DbProd.isoexpress));
  _apiServer.addApi(DaEnergyOffers(DbProd.isoexpress));
  _apiServer.addApi(RegulationRequirement(DbProd.isoexpress));
  _apiServer.addApi(WholesaleLoadCost(DbProd.isoexpress));

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

Future<Router> buildRouter() async {
  final router = Router();
  await DbProd.marks.open();
  await DbProd.riskSystem.open();

  router.mount('/calculators/v1/', ApiCalculators(DbProd.riskSystem).router);
  router.mount('/curve_ids/v1/', CurveIds(DbProd.marks).router);
  router.mount('/forward_marks/v1/', ForwardMarks(DbProd.marks).router);

  return router;
}

void main() async {
  await initializeTimeZone();
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  DbProd();
  await registerApis();
  _apiServer.enableDiscoveryApi();

  var port = 8080; // production
  //var port = 8081;  // test
  var server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  server.listen(_apiServer.httpRequestHandler);

  /// the new Shelf server
  final app = await buildRouter();
  app.get('/favicon.ico', (Request request) {
    return Response.ok('');
  });
  app.get('/', (Request request) {
    return Response.ok('Hello!  This is a Dart server.');
  });
  final handler = Pipeline().addMiddleware(cors()).addHandler(app);
  await io.serve(handler, host, port - 80);
  print('Shelf server started on port ${port - 80}');
}
