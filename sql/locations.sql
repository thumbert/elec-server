


CREATE TABLE locations 
AS SELECT *
FROM read_csv_auto('~/Downloads/Archive/PnodeTable/locations.csv', header = false, 
    columns = {
        'name': 'VARCHAR'
    }
);
