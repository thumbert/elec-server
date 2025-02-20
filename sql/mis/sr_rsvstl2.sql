SELECT * FROM tab3 LIMIT 5;




SELECT report_date, subaccount_id, asset_id, sum(rt_reserve_credit) as rt_reserve_credit
FROM tab3
WHERE report_date >= '2024-11-15'
AND report_date <= '2024-11-15'
GROUP BY subaccount_id, report_date, asset_id;

--- Get daily credits by asset for a particular settlement version
SET VARIABLE settlement = 0;
SELECT report_date, asset_id, 
    versions[LEAST(len(versions), getvariable('settlement') + 1)] as version,
    tmsr[LEAST(len(tmsr), getvariable('settlement') + 1)] as rt_tmsr_credit,
    tmnsr[LEAST(len(tmnsr), getvariable('settlement') + 1)] as rt_tmnsr_credit,
    tmor[LEAST(len(tmor), getvariable('settlement') + 1)] as rt_tmor_credit,
    total[LEAST(len(total), getvariable('settlement') + 1)] as rt_reserve_credit
FROM (
    SELECT report_date, asset_id, 
      array_agg(version) as versions,
      array_agg(tmsr_credit) as tmsr,
      array_agg(tmnsr_credit) as tmnsr,
      array_agg(tmor_credit) as tmor,
      array_agg(rt_reserve_credit) as total
    FROM (
        SELECT report_date, version, asset_id, 
            sum(rt_tmsr_credit) as tmsr_credit,
            sum(rt_tmnsr_credit) as tmnsr_credit,
            sum(rt_tmor_credit) as tmor_credit,
            sum(rt_reserve_credit) as rt_reserve_credit,
        FROM tab3
        WHERE report_date >= '2024-11-15'
        AND report_date <= '2024-11-15'
        AND account_id = 2
        -- AND subaccount_id = 'WHLGENLD'
        GROUP BY report_date, asset_id, version
        ORDER BY report_date, asset_id, version
    )
    GROUP BY report_date, asset_id
)
ORDER BY report_date, asset_id;

