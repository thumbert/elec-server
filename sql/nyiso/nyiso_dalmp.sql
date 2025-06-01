
SELECT min(day), max(day) FROM dalmp;

SELECT COUNT(*) FROM dalmp WHERE day = '2020-01-01'; -- 574 nodes 




SELECT day, ptid, lmp 
FROM dalmp
WHERE ptid = 61757
ORDER BY day;





--- ====================================================================================
--- Create and update the table
--- ====================================================================================
CREATE TABLE IF NOT EXISTS dalmp (
    day DATE NOT NULL,
    ptid INTEGER NOT NULL,
    lmp DECIMAL(9,2)[] NOT NULL,
    mcc DECIMAL(9,2)[] NOT NULL,
    mcl DECIMAL(9,2)[] NOT NULL,
);


LOAD zipfs;    
CREATE TEMPORARY TABLE tmp1 AS SELECT * FROM 'zip:///home/adrian/Downloads/Archive/Nyiso/DaLmpHourly/Raw/20200101damlbmp_zone_csv.zip/*.csv';
CREATE TEMPORARY TABLE tmp2 AS SELECT * FROM 'zip:///home/adrian/Downloads/Archive/Nyiso/DaLmpHourly/Raw/20200101damlbmp_gen_csv.zip/*.csv';

--- Transpose the data
CREATE TEMPORARY TABLE tmp_w AS
(SELECT 
    strptime("Time Stamp"[0:10], '%m/%d/%Y')::DATE AS "day",
    ptid::INTEGER AS ptid,
    list("LBMP ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "lmp",
    list("Marginal Cost Losses ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "mlc",
    list("Marginal Cost Congestion ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "mcc",
FROM tmp1
GROUP BY day, ptid
ORDER BY day, ptid)
UNION
(SELECT 
    strptime("Time Stamp"[0:10], '%m/%d/%Y')::DATE AS "day",
    ptid::INTEGER AS ptid,
    list("LBMP ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "lmp",
    list("Marginal Cost Losses ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "mlc",
    list("Marginal Cost Congestion ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "mcc",
FROM tmp2
GROUP BY day, ptid
ORDER BY day, ptid)
;    
-- SELECT Day, Ptid, LMP FROM tmp_w WHERE ptid = 61757;
-- SELECT day, ptid, lmp FROM tmp_w WHERE day = '2020-01-01' ORDER BY ptid;

INSERT INTO dalmp
SELECT day, ptid, lmp, mlc, mcc FROM tmp_w
EXCEPT 
    SELECT * FROM dalmp;            
        


