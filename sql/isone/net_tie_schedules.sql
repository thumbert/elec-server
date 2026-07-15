

-- INSTALL webbed FROM COMMUNITY;
LOAD webbed;


SELECT 
    area,
    time::TIMESTAMPTZ AS hour_beginning,
    MW::DECIMAL(9,1) AS mw 
FROM (
    SELECT 
        area,
        unnest(HourlyValue, recursive := true)
    FROM (
        SELECT 
            day::DATE AS day,
            unnest(NetTieSchedule, recursive := true),
        FROM read_xml('/home/adrian/Documents/repos/git/thumbert/elec-server/test/_assets/xml/net_tie_schedules.xml')
    )
);



