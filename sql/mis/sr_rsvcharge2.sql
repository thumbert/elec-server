
SELECT * FROM tab5 LIMIT 5;


SELECT report_date, subaccount_id, load_zone_id, sum(total_rt_reserve_charge) as total_rt_reserve_charges
FROM tab5
WHERE report_date >= '2024-11-15'
AND report_date <= '2024-11-15'
GROUP BY subaccount_id, report_date, load_zone_id;

--- Get daily charges by zone for a particular settlement version
SET VARIABLE settlement = 1;
SELECT report_date, load_zone_id, 
    versions[LEAST(len(versions), getvariable('settlement') + 1)] as version,
    trc[LEAST(len(trc), getvariable('settlement') + 1)] as total_rt_reserve_charge
FROM (
    SELECT report_date, load_zone_id, 
      array_agg(version) as versions,
      array_agg(total_rt_reserve_charge) as trc
    FROM (
        SELECT report_date, version, load_zone_id, 
            sum(total_rt_reserve_charge) as total_rt_reserve_charge,
        FROM tab5
        WHERE report_date >= '2024-11-15'
        AND report_date <= '2024-11-15'
        AND account_id = 2
        -- AND subaccount_id = 'WHLGENLD'
        GROUP BY report_date, load_zone_id, version
        ORDER BY report_date, load_zone_id, version
    )
    GROUP BY report_date, load_zone_id
)
ORDER BY report_date, load_zone_id;

