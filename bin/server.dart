import 'package:elec_server/api/isoexpress/api_isone_dacongestion.dart';
import 'package:elec_server/api/isoexpress/api_isone_regulation_requirement.dart';
import 'package:elec_server/api/isoexpress/api_isone_regulationoffers.dart';
import 'package:elec_server/api/isoexpress/api_wholesale_load_cost.dart';
import 'package:elec_server/api/marks/curves/curve_ids.dart';
import 'package:elec_server/api/marks/forward_marks.dart';
import 'package:elec_server/api/mis/api_sd_arrawdsum.dart';
import 'package:elec_server/api/mis/api_sr_dalocsum.dart';
import 'package:elec_server/api/mis/api_sr_rsvcharge.dart';
import 'package:elec_server/api/mis/api_sr_rtlocsum.dart';
import 'package:elec_server/api/mis/api_tr_sch2tp.dart';
import 'package:elec_server/api/mis/api_tr_sch3p2.dart';
import 'package:elec_server/api/risk_system/api_calculator.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/data/latest.dart';

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

Future<Router> buildRouter() async {
  final router = Router();

  await DbProd.isoexpress.open();
  <String, Router>{
    '/bc/v1/': BindingConstraints(DbProd.isoexpress).router,
    '/da_congestion_compact/v1/': DaCongestionCompact(DbProd.isoexpress).router,
    '/da_energy_offers/v1/': DaEnergyOffers(DbProd.isoexpress).router,
    '/da_demand_bids/v1/': DaDemandBids(DbProd.isoexpress).router,
    '/da_regulation_offers/v1/': DaRegulationOffers(DbProd.isoexpress).router,
    '/dalmp/v1/': DaLmp(DbProd.isoexpress).router,
    '/regulation_requirement/v1/':
        RegulationRequirement(DbProd.isoexpress).router,
    '/rt_load/v1/': WholesaleLoadCost(DbProd.isoexpress).router,
    '/rtlmp/v1/': RtLmp(DbProd.isoexpress).router,
    '/system_demand/v1/': SystemDemand(DbProd.isoexpress).router,
  }.forEach((key, value) {
    router.mount(key, value);
  });

  await DbProd.isone.open();
  await DbProd.marks.open();
  await DbProd.riskSystem.open();

  router.mount('/calculators/v1/', ApiCalculators(DbProd.riskSystem).router);
  router.mount('/curve_ids/v1/', CurveIds(DbProd.marks).router);
  router.mount('/forward_marks/v1/', ForwardMarks(DbProd.marks).router);
  router.mount('/ptids/v1/', ApiPtids(DbProd.isone).router);

  await DbProd.mis.open();
  <String, Router>{
    '/sd_arrawdsum/v1/': SdArrAwdSum(DbProd.mis).router,
    '/sr_dalocsum/v1/': SrDaLocSum(DbProd.mis).router,
    '/sr_rsvcharge/v1/': SrRsvCharge(DbProd.mis).router,
    '/sr_rtlocsum/v1/': SrRtLocSum(DbProd.mis).router,
    '/tr_sch2tp/v1/': TrSch2tp(DbProd.mis).router,
    '/tr_sch3p2/v1/': TrSch3p2(DbProd.mis).router,
  }.forEach((key, value) {
    router.mount(key, value);
  });

  return router;
}

void main() async {
  initializeTimeZones();
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  DbProd();

  const host = '127.0.0.1';
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
  await io.serve(handler, host, port);
  // await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Shelf server started on port $port');
}
