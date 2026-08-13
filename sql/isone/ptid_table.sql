select * from ptid_table;

SELECT * from ptid_table
WHERE node_type = 'load_zone';

SELECT DISTINCT activated_on
FROM ptid_table
ORDER BY activated_on DESC;


--- get the new ptids
SELECT *
FROM ptid_table
WHERE activated_on = (SELECT MAX(activated_on) FROM ptid_table);

--- get the deactivated ptids
SELECT *
FROM ptid_table
WHERE deactivated_on = (SELECT MAX(deactivated_on) FROM ptid_table)
ORDER BY ptid;

SELECT * FROM ptid_table
WHERE ptid = 77304;


---=======================================================================
--- Add an asof column to the ptid_table to track when a new ptid was added.
SET VARIABLE created_on = DATE '1999-01-01';
CREATE TABLE IF NOT EXISTS ptid_table (
    node_type ENUM('hub', 'node', 'load_zone', 'aggregation_zone', 'reserve_zone', 'interface') NOT NULL,
    ptid INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    substation_name VARCHAR,
    unit_name VARCHAR,
    unit_short_name VARCHAR,
    zone_id INTEGER,
    reserve_id INTEGER,
    rsp_area VARCHAR,
    dispatch_zone VARCHAR,
    dr_reserve_aggregation_zone_id INTEGER,
    activated_on DATE NOT NULL,
    deactivated_on DATE
);

INSERT INTO ptid_table
   VALUES 
    ('hub', 4000, '.H.INTERNAL_HUB', 'HUB', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4001, '.Z.MAINE', 'ME', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4002, '.Z.NEWHAMPSHIRE', 'NH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4003, '.Z.VERMONT', 'VT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4004, '.Z.CONNECTICUT', 'CT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4005, '.Z.RHODEISLAND', 'RI', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4006, '.Z.SEMASS', 'SEMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4007, '.Z.WCMASS', 'WCMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('load_zone', 4008, '.Z.NEMASSBOST', 'NEMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ---
    ('reserve_zone', 7000, 'REST OF SYSTEM', 'ROS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('reserve_zone', 7001, 'SOUTH WEST CONNECTICUT', 'SWCT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('reserve_zone', 7002, 'CONNECTICUT', 'CT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('reserve_zone', 7003, 'NEMASSBOST', 'NEMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ---
    ('interface', 4010, '.I.SALBRYNB345 1', 'NB', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4011, '.I.ROSETON 345 1', 'ROSETON', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4012, '.I.HQ_P1_P2345 5', 'PHASE 2', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4013, '.I.HQHIGATE120 2', 'HIGHGATE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4014, '.I.SHOREHAM138 99', 'CROSS SOUND CABLE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4015, '.I.NRTHPORT138 5', '1385 CABLE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('interface', 4016, '.I.HQMRL_RD345 1', 'NECEC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ---
    ('aggregation_zone', 7600, 'DR.CT_Eastern', 'ECT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7601, 'DR.CT_Northern', 'NCT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7602, 'DR.CT_Norwalk-Stamford', 'NRST', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7603, 'DR.CT_Western_SWCT', 'SWCT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7604, 'DR.CT_Western', 'WCT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7605, 'DR.ME_Bangor_Hydro', 'BNGR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7606, 'DR.ME_Maine', 'ME', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7607, 'DR.ME_Portland', 'PORT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7608, 'DR.MA_Boston', 'BSTN', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7609, 'DR.MA_North_Shore', 'NSHR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7610, 'DR.NH_New_Hampshire', 'NEWH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7611, 'DR.NH_Seacoast', 'SEAC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7612, 'DR.MA_Lower_SEMA', 'LSMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7613, 'DR.MA_SEMA', 'SEMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7614, 'DR.VT_Northwest_Vermont', 'NWVT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7615, 'DR.VT_Vermont', 'VT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7616, 'DR.MA_Central', 'CTMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7617, 'DR.MA_Springfield', 'SFLD', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7618, 'DR.MA_Western', 'WMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
    ('aggregation_zone', 7619, 'DR.RI_Rhode_Island', 'RI', NULL, NULL, NULL, NULL, NULL, NULL, NULL, getvariable('created_on'), null),
;

CREATE TEMPORARY TABLE tmp
AS (
    SELECT *
    FROM read_csv('/home/adrian/Downloads/Archive/PnodeTable/Raw/pnode_table.csv', 
        header = true, nullstr = 'null')
);
INSERT INTO ptid_table
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM ptid_table d
        WHERE
            d.ptid = t.ptid
    )
);

-- set the deactivated_on date for the nodes that are no longer in the tmp table
UPDATE ptid_table d
SET deactivated_on = (SELECT MIN(activated_on) FROM tmp)
WHERE NOT EXISTS (
    SELECT *
    FROM tmp t
    WHERE t.ptid = d.ptid
)
AND d.node_type = 'node'
AND d.deactivated_on IS NULL;




--- nodes in ptid_table with no matching ptid in tmp (likely deactivated)
SELECT d.*
FROM ptid_table d
LEFT JOIN tmp t ON d.ptid = t.ptid
WHERE t.ptid IS NULL
AND d.node_type = 'generator';
