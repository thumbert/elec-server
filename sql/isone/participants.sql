
-- get the list of participants for the latest as_of date
SELECT 
    id,
    customer_name,
    address1,
    address2,
    address3,
    city,   
    state,
    zip,
    country,
    phone,
    status,
    sector,
    participant_type,
    classification,
    sub_classification,
    has_voting_rights,
    termination_date
FROM participants
WHERE as_of = (
    SELECT MAX(as_of) FROM participants
)
ORDER BY id;




---==========================================================================================
CREATE TABLE IF NOT EXISTS participants (
    as_of DATE NOT NULL,
    id INT64 NOT NULL,
    customer_name VARCHAR NOT NULL,
    address1 VARCHAR,
    address2 VARCHAR,
    address3 VARCHAR,
    city VARCHAR,
    state VARCHAR,
    zip VARCHAR,
    country VARCHAR,
    phone VARCHAR,
    status ENUM('ACTIVE', 'SUSPENDED') NOT NULL,
    sector ENUM('Supplier', 'Not applicable', 'Alternative Resources', 'Generation', 'End User', 'Publicly-Owned Entity', 'Transmission', 'Market Participant') NOT NULL,
    participant_type ENUM('Participant', 'Non-Participant', 'Pool Operator') NOT NULL,
    classification ENUM('Market Participant', 'Governance Only', 'Group Member', 'Other', 'Local Control Center', 'Public Utility Commission', 'Transmission Only') NOT NULL,
    sub_classification VARCHAR,
    has_voting_rights BOOLEAN,
    termination_date DATE,
);


CREATE TEMPORARY TABLE tmp AS (
    SELECT *
    FROM read_csv(
        '/home/adrian/Downloads/Archive/Isone/Participants/Raw/participant_directory_2025-10-24.csv',
        skip = 5,
        delim = ',',
        quote = '"',
        strict_mode = false,
        ignore_errors = true,
        names = [
            'H',
            'ID',
            'Customer Name',
            'Address 1',
            'Address 2',
            'Address 3',
            'City',
            'State',
            'Zip',
            'Country',
            'Phone',
            'Status',
            'Sector',
            'Participant Type',
            'Classification',
            'Sub Classification',
            'Has Voting Rights',
            'Termination Date',
        ] 
    )
);

INSERT INTO participants BY NAME
(
    SELECT 
        '2025-10-24'::DATE AS as_of,
        "ID"::int64 AS id,
        "Customer Name"::VARCHAR AS customer_name,
        "Address 1"::VARCHAR AS address1,
        "Address 2"::VARCHAR AS address2,
        "Address 3"::VARCHAR AS address3,
        "City"::VARCHAR AS city,
        "State"::VARCHAR AS state,
        "Zip"::VARCHAR AS zip,
        "Country"::VARCHAR AS country,
        "Phone"::VARCHAR AS phone,
        "Status"::ENUM('ACTIVE', 'SUSPENDED') AS status,
        "Sector"::ENUM('Supplier', 'Not applicable', 'Alternative Resources', 'Generation', 'End User', 'Publicly-Owned Entity', 'Transmission', 'Market Participant') AS sector,
        "Participant Type"::ENUM('Participant', 'Non-Participant', 'Pool Operator') AS participant_type,
        "Classification"::ENUM('Market Participant', 'Governance Only', 'Group Member', 'Other', 'Local Control Center', 'Public Utility Commission', 'Transmission Only') AS classification,
        "Sub Classification"::VARCHAR AS sub_classification,
        CASE 
            WHEN "Has Voting Rights" = 'Y' THEN TRUE
            WHEN "Has Voting Rights" = 'N' THEN FALSE
            ELSE NULL
        END AS has_voting_rights,
        "Termination Date"::DATE AS termination_date
    FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM participants d
        WHERE d.id = t."ID"
        AND d.as_of = '2025-10-24'::DATE
    )
);

