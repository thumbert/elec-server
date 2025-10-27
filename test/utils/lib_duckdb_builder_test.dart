import 'package:elec_server/src/utils/lib_duckdb_builder.dart';
import 'package:test/test.dart';

void tests() {
  group('Test Rust stub builder for DuckDB', () {
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
      final rustStub = generateRustStub(input);
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

    test('make the QueryFilter structure', () {
      var columns = <Column>[
        Column(
            name: 'as_of',
            type: ColumnTypeDuckDB.date,
            isNullable: false,
            line: '')
          ..hasGteFilter = true
          ..hasLteFilter = true,
        Column(
            name: 'id',
            type: ColumnTypeDuckDB.int64,
            isNullable: false,
            line: '')
          ..hasInFilter = true,
      ];
      final queryStruct = makeQueryFilterStruct(columns);
      final expected = '''#[derive(Default)]
pub struct QueryFilter {
    pub as_of: Option<Date>,
    pub as_of_gte: Option<Date>,
    pub as_of_lte: Option<Date>,
    pub id: Option<i64>,
    pub id_in: Option<Vec<i64>>,
}
''';
      expect(queryStruct, expected);
    });

    test('make the QueryFilterBuilder structure', () {
      var columns = <Column>[
        Column(
            name: 'as_of',
            type: ColumnTypeDuckDB.date,
            isNullable: false,
            line: '')
          ..hasGteFilter = true
          ..hasLteFilter = true,
        Column(
            name: 'id',
            type: ColumnTypeDuckDB.int64,
            isNullable: false,
            line: '')
          ..hasInFilter = true,
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
}
''';
      print(queryStruct);
      expect(queryStruct, expected);
    });

    test('make function to query data, with date', () {
      var columns = <Column>[
        Column(
            name: 'as_of',
            type: ColumnTypeDuckDB.date,
            isNullable: false,
            line: '')
          ..hasGteFilter = true
          ..hasLteFilter = true,
        Column(
            name: 'id',
            type: ColumnTypeDuckDB.int64,
            isNullable: false,
            line: '')
          ..hasInFilter = true,
      ];
      final queryFn = makeQueryFunction('participants', columns);
      // print(queryFn);
      final expected =
          '''pub fn get_data(conn: &Connection, query_filter: &QueryFilter) -> Result<Vec<Record>, Box<dyn std::error::Error>> {
   let mut query = String::from(r#"
SELECT
    as_of,
    id
FROM participants WHERE 1=1
   "#);
    if let Some(as_of) = query_filter.as_of {
        query.push_str(&format!("AND as_of = '{}'", as_of));
    }
    if let Some(as_of_gte) = query_filter.as_of_gte {
        query.push_str(&format!("AND as_of_gte >= '{}'", as_of_gte));
    }
    if let Some(as_of_lte) = query_filter.as_of_lte {
        query.push_str(&format!("AND as_of_lte <= '{}'", as_of_lte));
    }
    if let Some(id) = query_filter.id {
        query.push_str(&format!("AND id = '{}'", id));
    }
    if let Some(id_in) = query_filter.id_in {
        query.push_str(&format!("AND id_in IN ({})", id_in));
    }
    query.push(';')
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

    test('make function to query data, with enum', () {
      var columns = <Column>[
        Column(
            name: 'status',
            type: ColumnTypeDuckDB.enumType,
            isNullable: false,
            line: ''),
        Column(
            name: 'id',
            type: ColumnTypeDuckDB.int64,
            isNullable: false,
            line: '')
          ..hasInFilter = true,
      ];
      final queryFn = makeQueryFunction('participants', columns);
      // print(queryFn);
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
    query.push(';')
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

    test('is column nullable', () {});
    test('make enum, 1', () {
      final enumCode = makeEnum(
          columnName: 'status',
          values: ['ACTIVE', 'SUSPENDED'],
          isNullable: false);
      final expected =
          '''#[derive(Clone, Copy, Debug, PartialEq, Serialize, Deserialize)]
pub enum Status {
    Active,
    Suspended,
}

impl std::str::FromStr for Status {
    type Err = ();
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "ACTIVE" => Ok(Status::Active),
            "SUSPENDED" => Ok(Status::Suspended),
            _ => Err(()),
        }
    }
}

impl std::fmt::Display for Status {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            Status::Active => write!(f, "ACTIVE"),
            Status::Suspended => write!(f, "SUSPENDED"),
        }
    }
}
''';
      // print(enumCode);
      expect(enumCode, expected);
    });
    test('make enum, 2', () {
      final enumCode = makeEnum(
          columnName: 'status',
          values: ['Participant', 'Non-Participant', 'Pool Operator'],
          isNullable: false);
      final expected =
          '''#[derive(Clone, Copy, Debug, PartialEq, Serialize, Deserialize)]
pub enum Status {
    Participant,
    NonParticipant,
    PoolOperator,
}

impl std::str::FromStr for Status {
    type Err = ();
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "Participant" => Ok(Status::Participant),
            "Non-Participant" => Ok(Status::NonParticipant),
            "Pool Operator" => Ok(Status::PoolOperator),
            _ => Err(()),
        }
    }
}

impl std::fmt::Display for Status {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            Status::Participant => write!(f, "Participant"),
            Status::NonParticipant => write!(f, "Non-Participant"),
            Status::PoolOperator => write!(f, "Pool Operator"),
        }
    }
}
''';
      // print(enumCode);
      expect(enumCode, expected);
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
  print(generateRustStub(input));
}

void main() {
  // tests();

  testIsoneParticipants();
}
