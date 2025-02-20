-- Use the built in function arg_max to get the latest settlement 
-- value.  It has the advantage of being cleaner than what I 
-- currently use in the MIS reports, but less general because 
-- it can only return the last settlement. 

-- Use arg_min to get the first settlement

CREATE TABLE data (name VARCHAR, version DATE, date DATE, value FLOAT);
INSERT INTO data VALUES 
    ('CMP', '2025-01-05', '2025-01-01', 101.1), 
    ('CMP', '2025-01-05', '2025-01-02', 102.1), 
    ('CMP', '2025-01-06', '2025-01-03', 103.1), 
    ('CMP', '2025-03-06', '2025-01-01', 101.2), 
    ('CMP', '2025-03-06', '2025-01-02', 102.2), 
    ('NECO', '2025-01-05', '2025-01-01', 51.1), 
    ('NECO', '2025-01-05', '2025-01-02', 52.1), 
    ('NECO', '2025-01-06', '2025-01-03', 53.1), 
;

SELECT * FROM data;


-- Pretty simple ...
SELECT name, date, 
  arg_max(version, version) as version,
  arg_max(value, version) as value
FROM data
GROUP BY name, date
ORDER BY name, date;


