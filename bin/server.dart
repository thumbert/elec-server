import 'package:elec_server/api/isoexpress/api_isone_regulation_requirement.dart';
import 'package:elec_server/api/isoexpress/api_wholesale_load_cost.dart';
import 'package:elec_server/api/marks/curves/curve_ids.dart';
import 'package:elec_server/api/marks/forward_marks.dart';
import 'package:elec_server/api/risk_system/api_calculator.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:logging/logging.dart';
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

const String host = '127.0.0.1';

Future<Router> buildRouter() async {
  final router = Router();

  await DbProd.isoexpress.open();
  await DbProd.isone.open();
  await DbProd.marks.open();
  await DbProd.riskSystem.open();

  router.mount('/bc/v1/', BindingConstraints(DbProd.isoexpress).router);
  router.mount('/calculators/v1/', ApiCalculators(DbProd.riskSystem).router);
  router.mount('/curve_ids/v1/', CurveIds(DbProd.marks).router);
  router.mount('/dalmp/v1/', DaLmp(DbProd.isoexpress).router);
  router.mount(
      '/da_energy_offers/v1/', DaEnergyOffers(DbProd.isoexpress).router);
  router.mount('/forward_marks/v1/', ForwardMarks(DbProd.marks).router);
  router.mount('/ptids/v1/', ApiPtids(DbProd.isone).router);
  router.mount('/regulation_requirement/v1/',
      RegulationRequirement(DbProd.isoexpress).router);
  router.mount('/rt_load/v1/', WholesaleLoadCost(DbProd.isoexpress).router);

  return router;
}

void main() async {
  await initializeTimeZone();
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  DbProd();

  var port = 8080; // production
  //var port = 8081;  // test

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
