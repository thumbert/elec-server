import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/api/api_dacongestion.dart';
import 'package:elec_server/api/api_lmp.dart';
import 'package:elec_server/api/api_energyoffers.dart';
import 'package:elec_server/api/api_masked_ids.dart';
import 'package:elec_server/api/cme/api_cme.dart';
import 'package:elec_server/api/isoexpress/api_fwdres_auction_results.dart';
import 'package:elec_server/api/isoexpress/api_isone_fuelmix.dart';
import 'package:elec_server/api/isoexpress/api_isone_monthly_asset_ncpc.dart';
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
import 'package:elec_server/api/nyiso/api_nyiso_bindingconstraints.dart'
    as nyiso_bc;
import 'package:elec_server/api/nyiso/api_nyiso_ptids.dart' as nyiso_ptids;
import 'package:elec_server/api/nyiso/api_nyiso_tcc_clearing_prices.dart'
    as nyiso_tcc_clearing_prices;
import 'package:elec_server/api/pjm/api_pjm_ptids.dart' as pjm_ptids;
import 'package:elec_server/api/polygraph/api_polygraph.dart';
import 'package:elec_server/api/risk_system/api_calculator.dart';
import 'package:elec_server/api/utilities/api_retail_suppliers_offers.dart';
import 'package:elec_server/api/weather/api_noaa_daily_summary.dart';
import 'package:elec_server/client/marks/forward_marks2.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/data/latest.dart';

import 'package:elec_server/api/isoexpress/api_isone_bindingconstraints.dart';
import 'package:elec_server/api/isoexpress/api_isone_demandbids.dart';
import 'package:elec_server/api/api_isone_ptids.dart';
import 'package:elec_server/api/isoexpress/api_system_demand.dart';
import 'package:elec_server/api/isoexpress/api_isone_zonal_demand.dart';
import 'package:elec_server/src/utils/cors_middleware.dart';

Future<Router> buildRouter() async {
  final router = Router();

  await DbProd.cme.open();
  router.mount('/forward_marks/v1', ApiCmeMarks(DbProd.cme).router);


  await DbProd.isoexpress.open();
  <String, Router>{
    '/bc/v1/': BindingConstraints(DbProd.isoexpress).router,
    '/da_energy_offers/v1/':
        DaEnergyOffers(DbProd.isoexpress, iso: Iso.newEngland).router,
    '/da_demand_bids/v1/': DaDemandBids(DbProd.isoexpress).router,
    '/da_regulation_offers/v1/': DaRegulationOffers(DbProd.isoexpress).router,
    '/dalmp/v1/': Lmp(DbProd.isoexpress, iso: Iso.newEngland, market: Market.da).router, // <--- to be deprecated on 1/27/2024!
    '/rtlmp/v1/': Lmp(DbProd.isoexpress, iso: Iso.newEngland, market: Market.rt).router, // <--- to be deprecated on 1/27/2024!
    '/isone/da/v1/': Lmp(DbProd.isoexpress, iso: Iso.newEngland, market: Market.da).router,
    '/isone/rt/v1/': Lmp(DbProd.isoexpress, iso: Iso.newEngland, market: Market.rt).router,

    '/isone/fuelmix/v1/': ApiIsoneFuelMix(DbProd.isoexpress).router,
    '/fwdres_auction_results/v1/':
        ApiFwdResAuctionResults(DbProd.isoexpress).router,
    '/isone/dacongestion/v1/':
        DaCongestionCompact(DbProd.isoexpress, iso: Iso.newEngland).router,
    '/monthly_asset_ncpc/v1/': ApiMonthlyAssetNcpc(DbProd.isoexpress).router,
    '/regulation_requirement/v1/':
        RegulationRequirement(DbProd.isoexpress).router,
    '/rt_load/v1/': WholesaleLoadCost(DbProd.isoexpress).router,
    '/system_demand/v1/': SystemDemand(DbProd.isoexpress).router,
    '/isone/zonal_demand/v1/': ZonalDemand(DbProd.isoexpress).router,
  }.forEach((key, value) {
    router.mount(key, value);
  });

  await DbProd.isone.open();
  router.mount('/isone/masked_ids/v1/', ApiMaskedIds(DbProd.isone).router);

  await DbProd.marks.open();

  await DbProd.nyiso.open();
  <String, Router>{
    '/nyiso/bc/v1/': nyiso_bc.BindingConstraints(DbProd.nyiso).router,
    '/nyiso/dacongestion/v1/':
        DaCongestionCompact(DbProd.nyiso, iso: Iso.newYork).router,
    '/nyiso/da_energy_offers/v1/':
        DaEnergyOffers(DbProd.nyiso, iso: Iso.newYork).router,
    '/nyiso/dalmp/v1/': Lmp(DbProd.nyiso, iso: Iso.newYork, market: Market.da).router,  // <--- to be deprecated on 1/27/2024!
    '/nyiso/da/v1/': Lmp(DbProd.nyiso, iso: Iso.newYork, market: Market.da).router,
    '/nyiso/rt/v1/': Lmp(DbProd.nyiso, iso: Iso.newYork, market: Market.rt).router,
    '/nyiso/masked_ids/v1/': ApiMaskedIds(DbProd.nyiso).router,
    '/nyiso/ptids/v1/': nyiso_ptids.ApiPtids(DbProd.nyiso).router,
    '/nyiso/tcc_clearing_prices/v1/':
        nyiso_tcc_clearing_prices.ApiNyisoTccClearingPrices(DbProd.nyiso)
            .router,
  }.forEach((key, value) {
    router.mount(key, value);
  });

  await DbProd.pjm.open();
  <String, Router>{
    '/pjm/ptids/v1/': pjm_ptids.ApiPtids(DbProd.pjm).router,
  }.forEach((key, value) {
    router.mount(key, value);
  });

  await DbProd.polygraph.open();
  <String, Router>{
    '/polygraph/v1/': ApiPolygraph(DbProd.polygraph).router,
  }.forEach((key, value) {
    router.mount(key, value);
  });

  await DbProd.riskSystem.open();
  router.mount('/calculators/v1/', ApiCalculators(DbProd.riskSystem).router);
  router.mount('/curve_ids/v1/', CurveIds(DbProd.marks).router);
  router.mount('/forward_marks/v1/', ForwardMarks(DbProd.marks).router);
  router.mount('/forward_marks/v2/', ApiCmeMarks(DbProd.cme).router);
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

  await DbProd.retailSuppliers.open();
  router.mount(
      '/retail_suppliers/v1/', ApiRetailSuppliersOffers(DbProd.retailSuppliers).router);

  await DbProd.weather.open();
  router.mount(
      '/noaa_daily_summary/v1/', ApiNoaaDailySummary(DbProd.weather).router);

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
