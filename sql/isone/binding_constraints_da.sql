SELECT * FROM constraints LIMIT 5;

SELECT min(hour_beginning) as min_hour_beginning,
       max(hour_beginning) as max_hour_beginning,
       count(*) as total_count
FROM constraints;

-- get the constraints for a given day
SET VARIABLE asof_date = DATE '2026-07-21';
SELECT * 
FROM constraints
WHERE hour_beginning::DATE = getvariable('asof_date')
ORDER BY constraint_name, hour_beginning;

-- get the first date a binding constraint appears
SELECT 
    constraint_name, 
    MIN(hour_beginning)::DATE AS first_appearance
FROM constraints
GROUP BY constraint_name
ORDER BY first_appearance DESC
LIMIT 20;


SET VARIABLE asof_date = DATE '2026-06-26';
SELECT constraint_name 
FROM (
    SELECT 
        constraint_name, 
        MIN(hour_beginning)::DATE AS first_appearance
    FROM constraints
    GROUP BY constraint_name
    ORDER BY first_appearance
)
WHERE first_appearance = getvariable('asof_date');




---========================================================================
CREATE TABLE IF NOT EXISTS constraints (
    hour_beginning TIMESTAMPTZ NOT NULL,
    constraint_name VARCHAR NOT NULL,
    contingency_name VARCHAR NOT NULL,
    marginal_value DECIMAL(9,2) NOT NULL,
);


CREATE TEMPORARY TABLE tmp AS
    SELECT 
        make_timestamptz(epoch_us(BeginDate)) AS hour_beginning,
        ConstraintName::VARCHAR AS constraint_name,
        ContingencyName::VARCHAR AS contingency_name,
        MarginalValue::DECIMAL(9,2) AS marginal_value
    FROM (
        SELECT unnest(DayAheadConstraints.DayAheadConstraint, recursive := true)
        FROM read_json('~/Downloads/Archive/IsoExpress/GridReports/DaBindingConstraints/Raw/2023/da_binding_constraints_final_2023*.json.gz')
    )
ORDER BY hour_beginning, constraint_name;


INSERT INTO constraints (
    SELECT * FROM tmp 
    WHERE NOT EXISTS (
        SELECT * FROM constraints d
        WHERE d.hour_beginning = tmp.hour_beginning
        AND d.constraint_name = tmp.constraint_name
        )
)
ORDER BY hour_beginning, constraint_name;


