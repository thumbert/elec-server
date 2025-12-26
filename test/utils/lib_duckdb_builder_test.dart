import 'dart:io';

import 'package:elec_server/src/utils/lib_duckdb_builder.dart';
import 'package:test/test.dart';

void tests() {
  group('Test Rust stub builder for DuckDB', () {
    test('make decimal Column from input', () {
      final input = '    mcc DECIMAL(18,5) NOT NULL,';
      final column = Column.from(input);
      expect(column.name, 'mcc');
      expect(column.type, ColumnTypeDuckDB.decimal);
      expect(column.isNullable, false);
    });

    test('make enum Column from input', () {
      final input = "    status ENUM('ACTIVE', 'SUSPENDED') not null,";
      final column = Column.from(input);
      expect(column.name, 'status');
      expect(column.type, ColumnTypeDuckDB.enumType);
      expect(column.isNullable, false);
    });

    test('example 1', () {
      final input = '''
CREATE TABLE IF NOT EXISTS participants (
    as_of DATE NOT NULL,
    id INT64 NOT NULL,
    customer_name VARCHAR NOT NULL,
    address1 VARCHAR,
    status ENUM('ACTIVE', 'SUSPENDED') NOT NULL,
    sector ENUM('Supplier', 'Not applicable', 'Alternative Resources', 'Generation', 'End User', 'Publicly-Owned Entity', 'Transmission', 'Market Participant') NOT NULL,
    participant_type ENUM('Participant', 'Non-Participant', 'Pool Operator') NOT NULL,
    sub_classification VARCHAR,
    has_voting_rights BOOLEAN,
    termination_date DATE,
);
''';
      final rustStub =
          CodeGenerator(input, language: Language.rust).generateCode();
      print(rustStub);
    });

    test('make Record struct', () {
      final input = '''
CREATE TABLE IF NOT EXISTS participants (
    as_of DATE NOT NULL,
    id INT64 NOT NULL,
    customer_name VARCHAR NOT NULL,
    address1 VARCHAR,
    status ENUM('ACTIVE', 'SUSPENDED') NOT NULL,
    sector ENUM('Supplier', 'Not applicable', 'Alternative Resources', 'Generation', 'End User', 'Publicly-Owned Entity', 'Transmission', 'Market Participant') NOT NULL,
    participant_type ENUM('Participant', 'Non-Participant', 'Pool Operator') NOT NULL,
    sub_classification VARCHAR,
    has_voting_rights BOOLEAN,
    termination_date DATE,
);
''';
      final columns = getColumns(input);
      final struct = makeStruct(columns);
      // print(struct);
      final expected =
          '''#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
pub struct Record {
    pub as_of: Date,
    pub id: i64,
    pub customer_name: String,
    pub address1: Option<String>,
    pub status: Status,
    pub sector: Sector,
    pub participant_type: ParticipantType,
    pub sub_classification: Option<String>,
    pub has_voting_rights: Option<bool>,
    pub termination_date: Option<Date>,
}
''';
      expect(struct, expected);
    });

    test('get column types', () {
      final input = '''
CREATE TABLE IF NOT EXISTS participants (
    as_of DATE NOT NULL,
    id INT64 NOT NULL,
);
''';
      final columns = getColumns(input);
      expect(columns.map((c) => c.type).toList(), [
        ColumnTypeDuckDB.date,
        ColumnTypeDuckDB.int64,
      ]);
    });

    test('get enum variants', () {
      expect(
          getEnumVariants('''status ENUM('ACTIVE', 'SUSPENDED') NOT NULL,'''),
          ['ACTIVE', 'SUSPENDED']);
      expect(
          getEnumVariants(
              "sector ENUM('Supplier', 'Not applicable', 'Alternative Resources', 'Generation', 'End User', 'Publicly-Owned Entity', 'Transmission', 'Market Participant') NOT NULL,"),
          [
            'Supplier',
            'Not applicable',
            'Alternative Resources',
            'Generation',
            'End User',
            'Publicly-Owned Entity',
            'Transmission',
            'Market Participant'
          ]);
      expect(
          getEnumVariants(
              "participant_type ENUM('Participant', 'Non-Participant', 'Pool Operator') NOT NULL,"),
          ['Participant', 'Non-Participant', 'Pool Operator']);
    });

    test('make Rust enum', () {
      final actual = makeEnum(
          columnName: 'sector',
          values: [
            'Supplier',
            'Not applicable',
            'Alternative Resources',
            'Generation',
            'End User',
            'Publicly-Owned Entity',
            'Transmission',
            'Market Participant'
          ],
          isNullable: false);
      // print(actual);
      var expected =
          File('test/utils/_golden/enum_sector.rs.gold').readAsStringSync();
      expect(actual, expected);
    });

    test('make SQL query', () {
      var columns = <Column>[
        Column(
          name: 'as_of',
          type: ColumnTypeDuckDB.date,
          isNullable: false,
        ),
        Column(
          name: 'id',
          type: ColumnTypeDuckDB.int64,
          isNullable: false,
        ),
        Column(
          name: 'name',
          type: ColumnTypeDuckDB.varchar,
          isNullable: false,
        ),
        Column(
          name: 'resource_type',
          type: ColumnTypeDuckDB.enumType,
          isNullable: false,
        ),
      ];
      final sqlQuery = makeSqlQuery('participants', columns);
      print(sqlQuery);
      expect(
          sqlQuery.contains(
              "    AND as_of IN ('{}')\", as_of_in.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(\"','\")));"),
          true);
      expect(
          sqlQuery.contains(
              "    AND id IN ({})\", id_in.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(\",\")));"),
          true);
      expect(
          sqlQuery.contains(
              "    AND name IN ('{}')\", name_in.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(\"','\")));"),
          true);
      expect(
          sqlQuery.contains(
              "    AND resource_type IN ('{}')\", resource_type_in.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(\"','\")));"),
          true);
    });

    test('make SQL query for timestamptz', () {
      var columns = <Column>[
        Column(
          name: 'time_start',
          type: ColumnTypeDuckDB.timestamptz,
          isNullable: true,
          timezoneName: 'America/New_York',
        ),
      ];
      final sqlQuery = makeSqlQuery('participants', columns);
      expect(
          sqlQuery.contains(
              "    if let Some(time_start) = &query_filter.time_start {"),
          true);
    });

    test('make the QueryFilter structure for date and int', () {
      var columns = <Column>[
        Column(
          name: 'as_of',
          type: ColumnTypeDuckDB.date,
          isNullable: false,
        ),
        Column(
          name: 'id',
          type: ColumnTypeDuckDB.int64,
          isNullable: false,
        ),
      ];
      final queryStruct = makeQueryFilterStruct(columns);
      final expected = '''#[derive(Debug, Default, Deserialize)]
pub struct QueryFilter {
    pub as_of: Option<Date>,
    pub as_of_in: Option<Vec<Date>>,
    pub as_of_gte: Option<Date>,
    pub as_of_lte: Option<Date>,
    pub id: Option<i64>,
    pub id_in: Option<Vec<i64>>,
    pub id_gte: Option<i64>,
    pub id_lte: Option<i64>,
}
''';
      expect(queryStruct, expected);
    });

    test('make the QueryFilter structure for hour_beginning', () {
      var columns = <Column>[
        Column(
          name: 'hour_beginning',
          type: ColumnTypeDuckDB.timestamptz,
          isNullable: false,
          timezoneName: 'America/New_York',
        ),
      ];
      final queryStruct = makeQueryFilterStruct(columns);
      final expected = '''#[derive(Debug, Default, Deserialize)]
pub struct QueryFilter {
    pub hour_beginning: Option<Zoned>,
    pub hour_beginning_gte: Option<Zoned>,
    pub hour_beginning_lt: Option<Zoned>,
}
''';
      expect(queryStruct, expected);
    });

    test('make the QueryFilter structure for f64', () {
      var columns = <Column>[
        Column(
          name: 'lmp',
          type: ColumnTypeDuckDB.double,
          isNullable: false,
        ),
      ];
      final queryStruct = makeQueryFilterStruct(columns);
      final expected = '''#[derive(Debug, Default, Deserialize)]
pub struct QueryFilter {
    pub lmp_gte: Option<f64>,
    pub lmp_lt: Option<f64>,
}
''';
      expect(queryStruct, expected);
    });

    test('make the QueryFilter structure for decimal', () {
      var columns = <Column>[
        Column.from('    mcc DECIMAL(18,5) NOT NULL,'),
      ];
      final queryStruct = makeQueryFilterStruct(columns);
      final expected = '''#[derive(Debug, Default, Deserialize)]
pub struct QueryFilter {
    pub mcc: Option<Decimal>,
    pub mcc_in: Option<Vec<Decimal>>,
    pub mcc_gte: Option<Decimal>,
    pub mcc_lte: Option<Decimal>,
}
''';
      expect(queryStruct, expected);
    });

    test('make the QueryFilterBuilder structure for a date and int', () {
      var columns = <Column>[
        Column(
          name: 'as_of',
          type: ColumnTypeDuckDB.date,
          isNullable: false,
        ),
        Column(
          name: 'id',
          type: ColumnTypeDuckDB.int64,
          isNullable: false,
        ),
      ];
      final queryStruct = makeQueryFilterBuilder(columns);
      final expected = '''#[derive(Default)]
pub struct QueryFilterBuilder {
    inner: QueryFilter,
}

impl QueryFilterBuilder {
    pub fn new() -> Self {
        Self {
            inner: QueryFilter::default(),
        }
    }

    pub fn build(self) -> QueryFilter {
        self.inner
    }

    pub fn as_of(mut self, value: Date) -> Self {
        self.inner.as_of = Some(value);
        self
    }

    pub fn as_of_in(mut self, values_in: Vec<Date>) -> Self {
        self.inner.as_of_in = Some(values_in);
        self
    }

    pub fn as_of_gte(mut self, value: Date) -> Self {
        self.inner.as_of_gte = Some(value);
        self
    }

    pub fn as_of_lte(mut self, value: Date) -> Self {
        self.inner.as_of_lte = Some(value);
        self
    }

    pub fn id(mut self, value: i64) -> Self {
        self.inner.id = Some(value);
        self
    }

    pub fn id_in(mut self, values_in: Vec<i64>) -> Self {
        self.inner.id_in = Some(values_in);
        self
    }

    pub fn id_gte(mut self, value: i64) -> Self {
        self.inner.id_gte = Some(value);
        self
    }

    pub fn id_lte(mut self, value: i64) -> Self {
        self.inner.id_lte = Some(value);
        self
    }
}
''';
      expect(queryStruct, expected);
    });

    test('make the QueryFilterBuilder structure for a zoned', () {
      var columns = <Column>[
        Column(
          name: 'hour_beginning',
          type: ColumnTypeDuckDB.timestamptz,
          isNullable: false,
          timezoneName: 'America/New_York',
        )
      ];
      final queryStruct = makeQueryFilterBuilder(columns);
      print(queryStruct);
      final expected = '''#[derive(Default)]
pub struct QueryFilterBuilder {
    inner: QueryFilter,
}

impl QueryFilterBuilder {
    pub fn new() -> Self {
        Self {
            inner: QueryFilter::default(),
        }
    }

    pub fn build(self) -> QueryFilter {
        self.inner
    }

    pub fn hour_beginning(mut self, value: Zoned) -> Self {
        self.inner.hour_beginning = Some(value);
        self
    }

    pub fn hour_beginning_gte(mut self, value: Zoned) -> Self {
        self.inner.hour_beginning_gte = Some(value);
        self
    }

    pub fn hour_beginning_lt(mut self, value: Zoned) -> Self {
        self.inner.hour_beginning_lt = Some(value);
        self
    }
}
''';
      expect(queryStruct, expected);
    });

    test('makeQueryFunction to query data, with date and int', () {
      var columns = <Column>[
        Column(
          name: 'as_of',
          type: ColumnTypeDuckDB.date,
          isNullable: false,
        ),
        Column(
          name: 'id',
          type: ColumnTypeDuckDB.int64,
          isNullable: false,
        ),
      ];
      final queryFn = makeQueryFunction('participants', columns);
      final expected =
          '''pub fn get_data(conn: &Connection, query_filter: &QueryFilter) -> Result<Vec<Record>, Box<dyn std::error::Error>> {
   let mut query = String::from(r#"
SELECT
    as_of,
    id
FROM participants WHERE 1=1"#);
    if let Some(as_of) = &query_filter.as_of {
        query.push_str(&format!("
    AND as_of = '{}'", as_of));
    }
    if let Some(as_of_in) = &query_filter.as_of_in {
        query.push_str(&format!("
    AND as_of IN ('{}')", as_of_in.iter().map(|v| v.to_string()).collect::<Vec<_>>().join("','")));
    }
    if let Some(as_of_gte) = &query_filter.as_of_gte {
        query.push_str(&format!("
    AND as_of >= '{}'", as_of_gte));
    }
    if let Some(as_of_lte) = &query_filter.as_of_lte {
        query.push_str(&format!("
    AND as_of <= '{}'", as_of_lte));
    }
    if let Some(id) = &query_filter.id {
        query.push_str(&format!("
    AND id = {}", id));
    }
    if let Some(id_in) = &query_filter.id_in {
        query.push_str(&format!("
    AND id IN ({})", id_in.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(",")));
    }
    if let Some(id_gte) = &query_filter.id_gte {
        query.push_str(&format!("
    AND id >= {}", id_gte));
    }
    if let Some(id_lte) = &query_filter.id_lte {
        query.push_str(&format!("
    AND id <= {}", id_lte));
    }
    query.push(';');

    let mut stmt = conn.prepare(&query)?;
    let rows = stmt.query_map([], |row| {
        let _n0 = 719528 + row.get::<usize, i32>(0)?;
        let as_of = Date::ZERO + _n0.days();
        let id: i64 = row.get::<usize, i64>(1)?;
        Ok(Record {
            as_of,
            id,
        })
    })?;
    let results: Vec<Record> = rows.collect::<Result<_, _>>()?;
    Ok(results)
}
''';
      expect(queryFn, expected);
    });

    test('makeQueryFunction to query data, with zoned', () {
      var columns = <Column>[
        Column(
          name: 'hour_beginning',
          type: ColumnTypeDuckDB.timestamptz,
          isNullable: false,
          timezoneName: 'America/New_York',
        ),
      ];
      final queryFn = makeQueryFunction('lmp', columns);
      print(queryFn);
      final expected =
          '''pub fn get_data(conn: &Connection, query_filter: &QueryFilter) -> Result<Vec<Record>, Box<dyn std::error::Error>> {
   let mut query = String::from(r#"
SELECT
    hour_beginning
FROM lmp WHERE 1=1
   "#);
    if let Some(hour_beginning) = &query_filter.hour_beginning {
        query.push_str(&format!("AND hour_beginning = '{}'", hour_beginning));
    }
    if let Some(hour_beginning_gte) = &query_filter.hour_beginning_gte {
        query.push_str(&format!("AND hour_beginning_gte >= '{}'", hour_beginning_gte));
    }
    if let Some(hour_beginning_lt) = &query_filter.hour_beginning_lt {
        query.push_str(&format!("AND hour_beginning_lt < '{}'", hour_beginning_lt));
    }
    query.push(';');
    let mut stmt = conn.prepare(&query)?;
    let rows = stmt.query_map([], |row| {
        let _micros0: i64 = row.get::<usize, i64>(0)?;
        let hour_beginning = Zoned::new(
                 Timestamp::from_microsecond(_micros0).unwrap(),
                 TimeZone::get("America/New_York").unwrap()
        );
        Ok(Record {
            hour_beginning,
        })
    })?;
    let results: Vec<Record> = rows.collect::<Result<_, _>>()?;
    Ok(results)
}
''';
      expect(queryFn, expected);
    });

    test('makeQueryFunction to query data, with f64', () {
      var columns = <Column>[
        Column(
          name: 'lmp',
          type: ColumnTypeDuckDB.double,
          isNullable: false,
        ),
      ];
      final queryFn = makeQueryFunction('lmp', columns);
      // print(queryFn);
      final expected =
          '''pub fn get_data(conn: &Connection, query_filter: &QueryFilter) -> Result<Vec<Record>, Box<dyn std::error::Error>> {
   let mut query = String::from(r#"
SELECT
    lmp
FROM lmp WHERE 1=1
   "#);
    if let Some(lmp_gte) = query_filter.lmp_gte {
        query.push_str(&format!("AND lmp_gte >= {}", lmp_gte));
    }
    if let Some(lmp_lt) = query_filter.lmp_lt {
        query.push_str(&format!("AND lmp_lt < {}", lmp_lt));
    }
    query.push(';');
    let mut stmt = conn.prepare(&query)?;
    let rows = stmt.query_map([], |row| {
        let lmp: f64 = row.get::<usize, f64>(0)?;
        Ok(Record {
            lmp,
        })
    })?;
    let results: Vec<Record> = rows.collect::<Result<_, _>>()?;
    Ok(results)
}
''';
      expect(queryFn, expected);
    });

    test('makeQueryFunction to query data, with enum', () {
      var columns = <Column>[
        Column(
          name: 'status',
          type: ColumnTypeDuckDB.enumType,
          isNullable: false,
        ),
        Column(
          name: 'id',
          type: ColumnTypeDuckDB.int64,
          isNullable: false,
        ),
      ];
      final queryFn = makeQueryFunction('participants', columns);
      print(queryFn);
      final expected =
          '''pub fn get_data(conn: &Connection, query_filter: &QueryFilter) -> Result<Vec<Record>, Box<dyn std::error::Error>> {
   let mut query = String::from(r#"
SELECT
    status,
    id
FROM participants WHERE 1=1
   "#);
    if let Some(status) = query_filter.status {
        query.push_str(&format!("AND status = '{}'", status));
    }
    if let Some(id) = query_filter.id {
        query.push_str(&format!("AND id = '{}'", id));
    }
    if let Some(id_in) = query_filter.id_in {
        query.push_str(&format!("AND id_in IN ({})", id_in));
    }
    query.push(';');
    let mut stmt = conn.prepare(&query)?;
    let rows = stmt.query_map([], |row| {
        let _n0: Status = match row.get_ref_unwrap(0) {
            duckdb::types::ValueRef::Enum(v) => v,
            _ => panic!("Unexpected value type for enum"),
        };
        let id: i64 = row.get::<usize, i64>(1)?;
        Ok(Record {
            status,
            id,
        })
    })?;
    let results: Vec<Record> = rows.collect::<Result<_, _>>()?;
    Ok(results)
}
''';
      expect(queryFn, expected);
    });

    test('generate Html for enum', () {
      final input = '''
CREATE TABLE IF NOT EXISTS tmp (
    resource_type ENUM('GENERATOR','INTERTIE', 'LOAD') NOT NULL,
    sch_bid_curve_type ENUM('BIDPRICE'),
);
''';
      final generator = CodeGenerator(input,
          timezoneName: 'America/Los_Angeles', language: Language.rust);
      var generateHtmlDocs = generator.generateHtmlDocs();
      print(generateHtmlDocs);
      // print(generateHtmlDocs);
    });
  });
}

void testIsoneParticipants() {
  final input = '''
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
''';
  print(CodeGenerator(input, language: Language.rust).generateCode());
}

void testIsone7dayCapacityReport() {
  final input = '''
CREATE TABLE IF NOT EXISTS capacity_forecast (
    for_day DATE NOT NULL,
    day_index UINT8 NOT NULL,
    cso_mw INT,
    cold_weather_outages_mw INT,
    other_gen_outages_mw INT,
    delist_mw INT,
    total_available_gen_mw INT,
    peak_import_mw INT,
    total_available_gen_import_mw INT,
    peak_load_mw INT,
    replacement_reserve_req_mw INT,
    required_reserve_mw INT,
    required_reserve_incl_replacement_mw INT,
    total_load_plus_required_reserve_mw INT,
    drr_mw INT,
    surplus_deficiency_mw INT,
    is_power_watch BOOLEAN,
    is_power_warn BOOLEAN, 
    is_cold_weather_watch BOOLEAN,
    is_cold_weather_warn BOOLEAN,
    is_cold_weather_event BOOLEAN,
    boston_high_temp_F INT1,
    boston_dew_point_F INT1,
    hartford_high_temp_F INT1,
    hartford_dew_point_F INT1,
);
''';
  print(CodeGenerator(input, language: Language.rust).generateCode());
}

void testSdTransact() {
  final input = '''
CREATE TABLE IF NOT EXISTS tab1 (
    account_id UINTEGER NOT NULL,
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    transaction_number UINTEGER NOT NULL,
    reference_id VARCHAR,
    transaction_type ENUM ('IBM') NOT NULL,
    other_party UINTEGER NOT NULL,
    settlement_location_id UINTEGER NOT NULL,
    location_name VARCHAR NOT NULL,
    location_type ENUM ('HUB', 'LOAD ZONE', 'NETWORK NODE', 'DRR AGGREGATION ZONE') NOT NULL,
    amount DECIMAL(9,4) NOT NULL,
    impacts_marginal_loss_revenue_allocation BOOLEAN NOT NULL,
    subaccount_id VARCHAR NOT NULL,
);
''';
  final generator = CodeGenerator(input,
      timezoneName: 'America/New_York', language: Language.rust);
  print(generator.generateCode());
  print(generator.generateHtmlDocs());
}

void testIsoneLmp() {
  final input = '''
CREATE TABLE IF NOT EXISTS da_lmp (
    hour_beginning TIMESTAMPTZ NOT NULL,
    ptid UINTEGER NOT NULL,
    lmp DECIMAL(9,4) NOT NULL,
    mcc DECIMAL(9,4) NOT NULL,
    mcl DECIMAL(9,4) NOT NULL,
);
''';
  final generator = CodeGenerator(input,
      timezoneName: 'America/Los_Angeles', language: Language.rust);
  print(generator.generateCode());
  print(generator.generateHtmlDocs());
}

void testCaisoLmp() {
  final input = '''
CREATE TABLE IF NOT EXISTS lmp (
    node_id VARCHAR NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    lmp DECIMAL(18,5) NOT NULL,
    mcc DECIMAL(18,5) NOT NULL,
    mcl DECIMAL(18,5) NOT NULL,
);
''';
  final generator = CodeGenerator(input,
      timezoneName: 'America/Los_Angeles', language: Language.rust);
  print(generator.generateCode());
  print(generator.generateHtmlDocs());
}

void testCaisoPublicBids() {
  final input = '''
CREATE TABLE IF NOT EXISTS public_bids_da (
    hour_beginning TIMESTAMPTZ NOT NULL,
    resource_type ENUM('GENERATOR','INTERTIE', 'LOAD') NOT NULL,
    scheduling_coordinator_seq UINTEGER NOT NULL,
    resource_bid_seq UINTEGER NOT NULL,
    time_interval_start TIMESTAMPTZ,
    time_interval_end TIMESTAMPTZ,
    product_bid_desc VARCHAR,
    product_bid_mrid VARCHAR,
    market_product_desc VARCHAR,
    market_product_type VARCHAR,
    self_sched_mw DECIMAL(9,4),
    sch_bid_time_interval_start TIMESTAMPTZ,
    sch_bid_time_interval_end TIMESTAMPTZ,
    sch_bid_xaxis_data DECIMAL(9,4),
    sch_bid_y1axis_data DECIMAL(9,4),
    sch_bid_y2axis_data DECIMAL(9,4),
    sch_bid_curve_type ENUM('BIDPRICE'),
    min_eoh_state_of_charge DECIMAL(9,4),
    max_eoh_state_of_charge DECIMAL(9,4),
);
''';
  final generator = CodeGenerator(input,
      requiredFilters: <String>[],
      timezoneName: 'America/Los_Angeles',
      language: Language.rust);
  print(generator.generateCode());
  // print(generator.generateHtmlDocs());
}

void main() {
  // tests();

  // testIsoneParticipants();
  // testIsone7dayCapacityReport();
  // testSdTransact();
  // testIsoneLmp();
  // testCaisoLmp();
  testCaisoPublicBids();
}
