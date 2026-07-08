SELECT * FROM capacity_offers_monthly LIMIT 5;



---=======================================================================
--- monthly auction bids/offers
CREATE TABLE IF NOT EXISTS capacity_offers_monthly (
    auction_month VARCHAR NOT NULL,
    forward_month VARCHAR NOT NULL,
    participant_id INTEGER NOT NULL,
    location_id INTEGER NOT NULL,
    row_type ENUM('BID', 'OFFER') NOT NULL,
    price DECIMAL(9,4) NOT NULL,
    mw DECIMAL(9,4) NOT NULL
);


CREATE TEMPORARY TABLE tmp
AS (
    -- Read the file as raw 5-column text to handle two concatenated sections
    -- (Bids and Offers), each with its own title and header line.
    WITH raw AS (
        SELECT
            row_number() OVER () AS n,
            col1, col2, col3, col4, col5
        FROM read_csv(
            '/home/adrian/Downloads/Archive/Nyiso/CapacityOffers/Raw/2024/20240101biddata_icapbids_obligation.csv.gz',
            header       = false,
            columns      = {'col1':'VARCHAR','col2':'VARCHAR','col3':'VARCHAR','col4':'VARCHAR','col5':'VARCHAR'},
            null_padding = true,
            auto_detect  = false
        )
    ),
    -- Locate the two section-title lines
    sections AS (
        SELECT
            max(CASE WHEN col1 ILIKE '%Monthly Bids%'   THEN n END) AS bids_start,
            max(CASE WHEN col1 ILIKE '%Monthly Offers%' THEN n END) AS offers_start
        FROM raw
    ),
    -- Extract auction_month from the title, e.g. "January 2024" -> "2024-01"
    auction AS (
        SELECT strftime(strptime(regexp_extract(col1, '^(\w+ \d{4})', 1), '%B %Y'), '%Y-%m') AS auction_month
        FROM raw
        WHERE col1 ILIKE '%Monthly Bids%'
        LIMIT 1
    )
    SELECT
        a.auction_month                                        AS auction_month,
        strftime(
            make_date(
                year(strptime(a.auction_month, '%Y-%m'))
                    + CASE WHEN month(strptime(trim(r.col1), '%B'))
                                < month(strptime(a.auction_month, '%Y-%m'))
                           THEN 1 ELSE 0 END,
                month(strptime(trim(r.col1), '%B')),
                1
            ),
            '%Y-%m'
        )                                                      AS forward_month,
        trim(r.col2)::INTEGER                                  AS participant_id,
        trim(r.col5)::INTEGER                                  AS location_id,
        CASE
            WHEN r.n > s.bids_start AND r.n < s.offers_start  THEN 'BID'
            ELSE 'OFFER'
        END::ENUM('BID', 'OFFER')                              AS row_type,
        trim(r.col3)::DECIMAL(9,4)                             AS price,
        trim(r.col4)::DECIMAL(9,4)                             AS mw
    FROM raw r
    CROSS JOIN sections s
    CROSS JOIN auction a
    WHERE
        r.n > s.bids_start               -- skip everything before first section
        AND r.col1 NOT ILIKE '%Monthly%' -- skip section title lines
        AND trim(r.col1) != 'Month_name' -- skip column header lines
        AND r.col1 IS NOT NULL
        AND trim(r.col1) != ''           -- skip blank separator lines
);

INSERT INTO capacity_offers_monthly
SELECT * FROM tmp t
WHERE NOT EXISTS (
    SELECT 1 FROM capacity_offers_monthly d
    WHERE
        d.auction_month  = t.auction_month  AND
        d.forward_month  = t.forward_month  AND
        d.location_id    = t.location_id    AND
        d.participant_id = t.participant_id AND
        d.row_type       = t.row_type       AND
        d.price          = t.price          AND
        d.mw             = t.mw
);
