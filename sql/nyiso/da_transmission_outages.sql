

SELECT *
FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/DaTransmissionOutages/Raw/20250801outSched_csv/202508*outSched.csv',
    columns = {
        'asof': 'DATE',
        'PTID': 'UINT',
        'facility_id': 'VARCHAR',
        'facility_name': 'VARCHAR',
        'facility_type': 'VARCHAR',
        'outage_start_date': 'DATE',
        'outage_start_hour': 'UINT1',
        'outage_end_date': 'DATE',
        'outage_end_hour': 'UINT1',
        'outage_mw': 'UINT16',
        'resource_id': 'VARCHAR',
        'resource_name': 'VARCHAR',
        'resource_type': 'VARCHAR',
        'zone': 'VARCHAR'
    }
)

