SELECT * FROM city_population_estimate;



---===================================================================
--- Census Population Estimates

CREATE TABLE city_population_estimate (
    rank INT NOT NULL,
    city_name VARCHAR NOT NULL,
    population_estimate INT NOT NULL,
);

CREATE TEMPORARY TABLE tmp AS 
    SELECT  
        Rank AS rank,
        "Geographic Area" AS city_name, 
        column7 AS population_estimate
    FROM read_csv(
            '/home/adrian/Documents/Cassie_SharedWithDad/city_population_estimate.csv',
            header = true, 
            skip = 2,
            thousands = ','
    )
    WHERE Rank IS NOT NULL
    AND column7 IS NOT NULL
;

INSERT INTO city_population_estimate (
    SELECT * FROM tmp
    WHERE NOT EXISTS 
    (
        SELECT 1 FROM city_population_estimate 
        WHERE city_population_estimate.rank = tmp.rank
        AND city_population_estimate.city_name = tmp.city_name
    )
);

