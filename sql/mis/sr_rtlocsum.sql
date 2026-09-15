SELECT * 
FROM tab1
WHERE report_date = '2026-09-01'
AND subaccount_id = 'WHLGENLD'
AND location_id = 4004
ORDER BY hour_beginning;



---=========================================================================
CREATE TABLE IF NOT EXISTS tab1 (
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    account_id UINTEGER NOT NULL,
    subaccount_id UINTEGER NOT NULL,
    subaccount_name VARCHAR NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    location_id UINTEGER NOT NULL,
    location_name VARCHAR NOT NULL,
    location_type ENUM ('LOAD ZONE', 'NETWORK NODE', 'HUB', 'DRR AGGREGATION ZONE') NOT NULL,
    revenue_metered_generation DOUBLE,
    scheduled_imports DOUBLE,
    rt_generation_obligation DOUBLE,
    revenue_metered_load DOUBLE, 
    scheduled_exports DOUBLE, 
    internal_bilateral_for_load DOUBLE,
    rt_load_obligation DOUBLE,
    rt_internal_bilateral_for_market_purchases DOUBLE,
    rt_internal_bilateral_for_market_sales DOUBLE,
    rt_adjusted_load_obligation DOUBLE,
    rt_adjusted_net_interchange DOUBLE,
    adjusted_net_interchange_deviation DOUBLE,
    rt_energy_component DOUBLE,
    rt_congestion_component DOUBLE,
    rt_marginal_loss_component DOUBLE,
    rt_energy_charge_or_credit DOUBLE,
    rt_congestion_charge_or_credit DOUBLE,
    rt_loss_charge_or_credit DOUBLE,
    rt_internal_bilateral_for_market_purchases_impacting_mlrlo DOUBLE,
    rt_internal_bilateral_for_market_sales_impacting_mlrlo DOUBLE,
    marginal_loss_revenue_load_obligation DOUBLE, 
    rt_generation_obligation_for_charge_allocation DOUBLE, 
    rt_load_obligation_for_charge_allocation DOUBLE, 
    rt_adjusted_net_interchange_for_charge_allocation DOUBLE,
    rt_demand_reduction_obligation DOUBLE,
    rt_load_obligation_for_demand_reduction_allocation DOUBLE,
    demand_reduction_obligation_deviation DOUBLE,
    rt_demand_reduction_credit DOUBLE, 
    rt_demand_reduction_charge DOUBLE, 
    rt_satoa_obligation DOUBLE, 
);
CREATE INDEX idx ON tab1 (report_date, account_id, subaccount_id);
