


---=======================================================================
CREATE TABLE IF NOT EXISTS zonal_uplift (
    day DATE NOT NULL,
    ptid VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    uplift_category VARCHAR NOT NULL,
    uplift_payment DECIMAL(9,2) NOT NULL,
);

CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        strptime("Market Day", '%m/%d/%Y')::DATE AS day,
        PTID::VARCHAR AS ptid,
        "Name"::VARCHAR AS name,
        "Uplift Payment Category"::VARCHAR AS uplift_category,
        "Uplift Payment Amount"::DECIMAL(9,2) AS uplift_payment
    FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/ZonalUplift/Raw/2025/202512*zonal_uplift.csv', 
        header = true
));

INSERT INTO zonal_uplift
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM zonal_uplift d
        WHERE
            d.day = t.day AND
            d.ptid = t.ptid AND
            d.name = t.name AND
            d.uplift_category = t.uplift_category AND
            d.uplift_payment = t.uplift_payment
    )
);
