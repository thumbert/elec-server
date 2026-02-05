select * from events_calendar
WHERE event_title LIKE 'Day Ahead Market Results%' 
ORDER BY event_start
limit 10;



---===========================================================================
CREATE TABLE IF NOT EXISTS events_calendar (
    event_id UINTEGER NOT NULL,
    event_published TIMESTAMPTZ NOT NULL,
    event_start TIMESTAMPTZ,
    event_end TIMESTAMPTZ,
    event_title TEXT NOT NULL,
    event_description TEXT NOT NULL,
    PRIMARY KEY (event_id)
);


CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        CAST(aux ->> '$.event_id' AS UINTEGER) AS event_id,
        timezone('UTC', CAST(aux ->> '$.event_publish_date_gmt_str' AS TIMESTAMP)) AS event_published,
        timezone('UTC', CAST(aux ->> '$.event_start_date_gmt_str' AS TIMESTAMP)) AS event_start,
        timezone('UTC', CAST(aux ->> '$.event_end_date_gmt_str' AS TIMESTAMP)) AS event_end,
        CAST(aux ->> '$.event_title' AS TEXT) AS event_title,
        CAST(aux ->> '$.event_description' AS TEXT) AS event_description,
    FROM 
        (
        SELECT 
            CAST(unnest(events) AS JSON) as aux, 
        FROM read_json('~/Downloads/Archive/Isone/EventsCalendar/Raw/2025/events_202501*.json.gz')
        )
);

INSERT INTO events_calendar
    SELECT * FROM tmp
WHERE NOT EXISTS (
    SELECT * FROM events_calendar
        WHERE events_calendar.event_id = tmp.event_id
) ORDER BY event_id;
