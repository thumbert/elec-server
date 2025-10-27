SELECT MIN(as_of) AS as_of_min, MAX(as_of) AS as_of_max, COUNT(*) AS cnt
FROM scheduled_outages;


SELECT *
FROM scheduled_outages
WHERE 
AND outage_start_date >= '2025-10-01'
AND outage_start_date <= '2026-01-01'
AND equipment_type = 'LINE';



SELECT *
FROM scheduled_outages
WHERE as_of = '2025-09-24'
AND equipment_name LIKE 'CLAY%'
AND equipment_type = 'LINE';


---=======================================================================
CREATE TABLE IF NOT EXISTS scheduled_outages (
    as_of DATE NOT NULL,
    ptid INT64 NOT NULL,
    outage_id VARCHAR NOT NULL,
    equipment_name VARCHAR NOT NULL,
    equipment_type VARCHAR NOT NULL,
    outage_start_date DATE NOT NULL,
    outage_time_out TIME NOT NULL,
    outage_end_date DATE NOT NULL,
    outage_time_in TIME NOT NULL,
    called_in_by VARCHAR NOT NULL,
    status VARCHAR,
    last_update TIMESTAMP,
    message VARCHAR,
    arr INT64
);

CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        CURRENT_DATE AS as_of,
        "PTID"::int64 AS ptid,
        "Outage ID"::VARCHAR AS outage_id,
        "Equipment Name"::VARCHAR AS equipment_name,
        "Equipment Type"::VARCHAR AS equipment_type,
        "Date Out"::DATE AS outage_start_date,
        "Time Out"::TIME AS outage_time_out,
        "Date In"::DATE AS outage_end_date,
        "Time In"::TIME AS outage_time_in,
        "Called In"::VARCHAR AS called_in_by,
        "Status"::VARCHAR AS status,
        strptime("Status Date", '%m-%d-%Y %H:%M') AS last_update,
        "Message"::VARCHAR AS message,
        "ARR"::int64 AS arr,
    FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/TransmissionOutages/Scheduled/Raw/2025/outage_schedule_2025-09-24.csv.gz')
);


INSERT INTO scheduled_outages
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM scheduled_outages d
        WHERE
            d.as_of = t.as_of AND
            d.ptid = t.ptid AND
            d.outage_id = t.outage_id AND
            d.equipment_name = t.equipment_name AND
            d.equipment_type = t.equipment_type AND
            d.outage_start_date = t.outage_start_date AND
            d.outage_time_out = t.outage_time_out AND
            d.outage_end_date = t.outage_end_date AND
            d.outage_time_in = t.outage_time_in AND
            d.called_in_by = t.called_in_by AND
            d.status = t.status AND
            d.last_update = t.last_update
    )
);
