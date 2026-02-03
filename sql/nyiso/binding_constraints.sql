

SELECT * FROM binding_constraints;
WHERE hour_beginning >= '2025-11-01'

SELECT MIN(hour_beginning) AS hour_beginning_min, MAX(hour_beginning) AS hour_beginning_max, COUNT(*) AS cnt
FROM binding_constraints;





---=======================================================================
CREATE TABLE IF NOT EXISTS binding_constraints (
    market ENUM('DA', 'RT') NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    limiting_facility VARCHAR NOT NULL,
    facility_ptid INT64 NOT NULL,
    contingency VARCHAR NOT NULL,
    constraint_cost DECIMAL(9,4) NOT NULL,
);

CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        'DA' AS market,
        case "TIME ZONE" 
            when 'EST' then strptime("Time Stamp" || ' -0500', '%m/%d/%Y %H:%M %z')::TIMESTAMPTZ
            when 'EDT' then strptime("Time Stamp" || ' -0400', '%m/%d/%Y %H:%M %z')::TIMESTAMPTZ
            else NULL
        end AS hour_beginning, 
        "Limiting Facility"::VARCHAR AS limiting_facility,
        "Facility PTID"::INT64 AS facility_ptid,
        "Contingency"::VARCHAR AS contingency,
        "Constraint Cost($)"::DECIMAL(9,4) AS constraint_cost
    FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/DaBindingConstraints/Raw/2025/202511*DAMLimitingConstraints.csv', 
        header = true,
        types = {'Facility PTID': 'INT64', 'Constraint Cost($)': 'DECIMAL(9,4)'}
));


INSERT INTO binding_constraints
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM binding_constraints d
        WHERE
            d.market = t.market AND
            d.hour_beginning = t.hour_beginning AND
            d.limiting_facility = t.limiting_facility AND
            d.facility_ptid = t.facility_ptid AND
            d.contingency = t.contingency AND
            d.constraint_cost = t.constraint_cost
    )
);
