part of 'lib_duckdb_builder.dart';

String addImports(List<Column> columns) {
  final buffer = StringBuffer();
  // buffer.writeln('use std::error::Error;');
  // buffer.writeln('use log::{error, info};');
  buffer.writeln('use serde::{Serialize, Deserialize};');
  buffer.writeln('use duckdb::Connection;');
  buffer.writeln('');

  bool hasDecimal = false;
  bool hasDate = false;
  bool hasEnum = false;
  bool hasTime = false;
  bool hasTimestamp = false;
  bool hasTimestamptz = false;
  for (var column in columns) {
    switch (column.type) {
      case ColumnTypeDuckDB.date:
        hasDate = true;
        break;
      case ColumnTypeDuckDB.decimal:
        hasDecimal = true;
        break;
      case ColumnTypeDuckDB.enumType:
        hasEnum = true;
      case ColumnTypeDuckDB.time:
        hasTime = true;
        break;
      case ColumnTypeDuckDB.timestamp:
        hasTimestamp = true;
        break;
      case ColumnTypeDuckDB.timestamptz:
        hasTimestamptz = true;
        break;
      default:
        break;
    }
  }

  if (hasDate) {
    buffer.writeln('use jiff::{civil::Date, ToSpan};');
  }
  if (hasDecimal) {
    buffer.writeln('use rust_decimal::Decimal;');
  }
  if (hasEnum) {
    buffer.writeln('use std::str::FromStr;');
  }
  if (hasTime) {
    buffer.writeln('use jiff::civil::Time;');
  }
  if (hasTimestamp) {
    buffer.writeln('use jiff::Timestamp;');
  }
  if (hasTimestamptz) {
    buffer.writeln('use jiff::Zoned;');
  }

  buffer.writeln();
  return buffer.toString();
}

String makeStruct(List<Column> columns) {
  final buffer = StringBuffer();
  buffer.writeln('#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]');
  buffer.writeln('pub struct Record {');
  for (var column in columns) {
    final rustType = getRustType(
      type: column.type,
      columnName: column.name,
      isNullable: column.isNullable,
    );
    if (rustType == 'Decimal') {
      buffer.writeln('    #[serde(with = "rust_decimal::serde::float")]');
    }
    buffer.writeln('    pub ${column.name.toSnakeCase()}: $rustType,');
  }
  buffer.writeln('}');
  return buffer.toString();
}

/// Get the Rust type corresponding to the DuckDB column type.
/// Need the [columnName] for an enumerated type.
String getRustType({
  required ColumnTypeDuckDB type,
  required String columnName,
  required bool isNullable,
}) {
  switch (type) {
    case ColumnTypeDuckDB.boolean:
      return isNullable ? 'Option<bool>' : 'bool';
    case ColumnTypeDuckDB.date:
      return isNullable ? 'Option<Date>' : 'Date';
    case ColumnTypeDuckDB.decimal:
      return isNullable ? 'Option<f64>' : 'f64';
    case ColumnTypeDuckDB.tinyint:
      return isNullable ? 'Option<i8>' : 'i8';
    case ColumnTypeDuckDB.int16:
      return isNullable ? 'Option<i16>' : 'i16';
    case ColumnTypeDuckDB.int32:
      return isNullable ? 'Option<i32>' : 'i32';
    case ColumnTypeDuckDB.int64:
      return isNullable ? 'Option<i64>' : 'i64';
    case ColumnTypeDuckDB.float:
      return isNullable ? 'Option<f32>' : 'f32';
    case ColumnTypeDuckDB.double:
      return isNullable ? 'Option<f64>' : 'f64';
    case ColumnTypeDuckDB.varchar:
      return isNullable ? 'Option<String>' : 'String';
    case ColumnTypeDuckDB.time:
      return isNullable ? 'Option<Time>' : 'Time';
    case ColumnTypeDuckDB.timestamp:
      return isNullable ? 'Option<Timestamp>' : 'Timestamp';
    case ColumnTypeDuckDB.enumType:
      return isNullable
          ? 'Option<${columnName.toPascalCase()}>'
          : columnName.toPascalCase();
    case ColumnTypeDuckDB.uint8:
      return isNullable ? 'Option<u8>' : 'u8';
    case ColumnTypeDuckDB.uint16:
      return isNullable ? 'Option<u16>' : 'u16';
    case ColumnTypeDuckDB.uint32:
      return isNullable ? 'Option<u32>' : 'u32';
    case ColumnTypeDuckDB.uint64:
      return isNullable ? 'Option<u64>' : 'u64';
    case ColumnTypeDuckDB.timestamptz:
      return isNullable ? 'Option<Zoned>' : 'Zoned';
    case ColumnTypeDuckDB.uint128:
      return isNullable ? 'Option<u128>' : 'u128';
  }
}

/// Generate a Rust enum from a DuckDB ENUM column.
/// Make sure that the variant name is in Pascal case.
/// * [columnName] the DuckDB column name,
/// * [values] the list of ENUM values in DuckDB,
/// * [isNullable] whether the column is nullable.
String makeEnum(
    {required String columnName,
    required List<String> values,
    required bool isNullable}) {
  final enumName = columnName.toPascalCase();
  final buffer = StringBuffer();
  buffer.writeln(
      '#[derive(Clone, Copy, Debug, PartialEq, Serialize, Deserialize)]');
  buffer.writeln('pub enum $enumName {');
  for (var value in values) {
    final variantName = value.replaceAll(' ', '_').toPascalCase();
    buffer.writeln('    $variantName,');
  }
  buffer.writeln('}');

  // implement FromStr for the enum to parse from string
  buffer.writeln('\nimpl std::str::FromStr for $enumName {');
  buffer.writeln('    type Err = ();');
  buffer.writeln('    fn from_str(s: &str) -> Result<Self, Self::Err> {');
  buffer.writeln('        match s {');
  for (var value in values) {
    final variantName = value.replaceAll(' ', '_').toPascalCase();
    buffer.writeln('            "$value" => Ok($enumName::$variantName),');
  }
  buffer.writeln('            _ => Err(()),');
  buffer.writeln('        }');
  buffer.writeln('    }');
  buffer.writeln('}');

  // implement Display so that the Serde serializer prints the correct output
  buffer.writeln('\nimpl std::fmt::Display for $enumName {');
  buffer.writeln(
      '    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {');
  buffer.writeln('        match self {');
  for (var value in values) {
    final variantName = value.replaceAll(' ', '_').toPascalCase();
    buffer
        .writeln('            $enumName::$variantName => write!(f, "$value"),');
  }
  buffer.writeln('        }');
  buffer.writeln('    }');
  buffer.writeln('}');

  // implement a custom Deserializer so that the Actix path can parse different
  // casing.
  // buffer.writeln("\nimpl<'de> serde::Deserialize<'de> for $enumName {");
  // buffer.writeln('    fn derialize<D>(deserializer: D) -> Result<Self, D::Error>');
  // buffer.writeln('    where');
  // buffer.writeln("        D: serde::Deserializer<'de>,");
  // buffer.writeln('    {');
  // buffer.writeln('        let s = String::deserialize(deserializer)?;');
  // buffer.writeln('        $enumName::from_str(&s.to_ascii_uppercase()).map_err(serde::de::Error::custom)');
  // buffer.writeln('}');

  return buffer.toString();
}

String makeQueryFunction(String tableName, List<Column> columns) {
  final buffer = StringBuffer();

  var query = 'SELECT\n    ';
  query += columns.map((c) => c.name.toSnakeCase()).join(',\n    ');
  query += '\nFROM $tableName WHERE 1=1';

  buffer.writeln(
      'pub fn get_data(conn: &Connection, query_filter: &QueryFilter) -> Result<Vec<Record>, Box<dyn std::error::Error>> {');
  buffer.writeln('   let mut query = String::from(r#"\n$query');
  buffer.writeln('   "#);');
  // create the filters from the query parameters
  for (var column in columns) {
    var variables = column.getQueryFilterVariables();
    for (var variable in variables) {
      var borrow = '';
      if (['String', 'Option<String>'].contains(variable.rustType)) {
        borrow = '&';
      }
      buffer.writeln(
          '    if let Some(${variable.rustVariableName}) = ${borrow}query_filter.${variable.rustVariableName} {');
      buffer.writeln(
          "        query.push_str(&format!(\"${variable.getFilterClause()}\", ${variable.rustVariableName}));");
      buffer.writeln('    }');
    }
  }
  buffer.writeln("    query.push(';');");

  // prepare and execute the query
  buffer.writeln('    let mut stmt = conn.prepare(&query)?;');
  buffer.writeln('    let rows = stmt.query_map([], |row| {');
  for (var (i, column) in columns.indexed) {
    final rustType = getRustType(
      type: column.type,
      columnName: column.name,
      isNullable: column.isNullable,
    );
    final name = column.name.toSnakeCase();
    switch (column.type) {
      case ColumnTypeDuckDB.date:
        if (column.isNullable) {
          buffer.writeln('        let $name = row\n'
              '            .get::<usize, Option<i32>>($i)?\n'
              '            .map(|n| {Date::ZERO + (719528 + n).days() });');
          break;
        } else {
          buffer.writeln(
              '        let _n$i = 719528 + row.get::<usize, i32>($i)?;');
          buffer.writeln('        let $name = Date::ZERO + _n$i.days();');
        }
        break;
      case ColumnTypeDuckDB.decimal:
        buffer.writeln(
            '        let $name: $rustType = match row.get_ref_unwrap($i) {\n'
            '            duckdb::types::ValueRef::Decimal(v) => v,\n'
            '            _ => Decimal::MIN,\n'
            '        };');
        break;
      case ColumnTypeDuckDB.enumType:
        buffer.writeln(
            '        let _n$i = match row.get_ref_unwrap($i).to_owned() {\n'
            '            duckdb::types::Value::Enum(v) => v,\n'
            '            _ => panic!("Unexpected value type for enum"),\n'
            '        };');
        buffer.writeln(
            '        let $name = $rustType::from_str(&_n$i).unwrap();');
        break;
      case ColumnTypeDuckDB.time:
        buffer.writeln(
            '        let _micros$i: i64 = row.get::<usize, i64>($i)?;');
        buffer.writeln(
            '        let $name = Time::midnight() + _micros$i.microseconds();');
        break;
      case ColumnTypeDuckDB.timestamptz:
        buffer.writeln(
            '        let _micros$i: i64 = row.get::<usize, i64>($i)?;');
        buffer.writeln('        let $name = Zoned::new(\n'
            '                 Timestamp::from_microseconds(_micros$i).unwrap(),\n'
            '                 TimeZone::get("${column.timezoneName}").unwrap()\n'
            '        );');
        break;
      case ColumnTypeDuckDB.boolean:
      case ColumnTypeDuckDB.int16:
      case ColumnTypeDuckDB.int32:
      case ColumnTypeDuckDB.int64:
      case ColumnTypeDuckDB.tinyint:
      case ColumnTypeDuckDB.uint64:
      case ColumnTypeDuckDB.uint32:
      case ColumnTypeDuckDB.uint16:
      case ColumnTypeDuckDB.uint8:
      case ColumnTypeDuckDB.varchar:
        buffer.writeln(
            '        let $name: $rustType = row.get::<usize, $rustType>($i)?;');
        break;
      default:
        throw UnimplementedError('Type $rustType not implemented in get_data');
    }
  }
  buffer.writeln('        Ok(Record {');
  for (var column in columns) {
    final name = column.name.toSnakeCase();
    buffer.writeln('            $name,');
  }
  buffer.writeln('        })');
  buffer.writeln('    })?;');
  buffer.writeln(
      '    let results: Vec<Record> = rows.collect::<Result<_, _>>()?;');
  buffer.writeln('    Ok(results)');
  buffer.writeln('}');

  return buffer.toString();
}

/// Construct the struct use to query the data.  It contains the filter fields
/// that closely match the ones of the Record struct.  By default Date, Timestamp
/// and Zoned fields get a range filter (start, end).
///
/// Sometimes, it's nice to have a partial filter on a VARCHAR, i.e., a
/// "like" filter.  But you don't need it on all the fields.  You can specify
/// that with the [likeFilters] parameter.  Same with the [inFilters].
///
/// All query fields are optional.
///
String makeQueryFilterStruct(List<Column> columns) {
  final buffer = StringBuffer();
  buffer.writeln('#[derive(Default, Deserialize)]');
  buffer.writeln('pub struct QueryFilter {');
  for (var column in columns) {
    final rustType = getRustType(
      type: column.type,
      columnName: column.name,
      isNullable: false,
    );
    final filters = column.getQueryFilterVariables();
    for (var filter in filters) {
      switch (filter.filterClause) {
        case FilterClause.equal:
          buffer.writeln('    pub ${column.name}: Option<$rustType>,');
          break;
        case FilterClause.greaterThanOrEqual:
          buffer.writeln('    pub ${column.name}_gte: Option<$rustType>,');
          break;
        case FilterClause.lessThanOrEqual:
          buffer.writeln('    pub ${column.name}_lte: Option<$rustType>,');
          break;
        case FilterClause.like:
          buffer.writeln('    pub ${column.name}_like: Option<String>,');
          break;
        case FilterClause.inList:
          buffer.writeln('    pub ${column.name}_in: Option<Vec<$rustType>>,');
          break;
      }
    }
  }
  buffer.writeln('}');

  return buffer.toString();
}

String makeQueryFilterBuilder(List<Column> columns) {
  final buffer = StringBuffer();

  buffer.writeln('#[derive(Default)]');
  buffer.writeln('pub struct QueryFilterBuilder {');
  buffer.writeln('    inner: QueryFilter,');
  buffer.writeln('}');

  buffer.writeln('\nimpl QueryFilterBuilder {');
  buffer.writeln('''
    pub fn new() -> Self {
        Self {
            inner: QueryFilter::default(),
        }
    }

    pub fn build(self) -> QueryFilter {
        self.inner
    }''');

  for (var column in columns) {
    final rustType = getRustType(
      type: column.type,
      columnName: column.name,
      isNullable: false,
    );
    final name = column.name.toSnakeCase();
    final filters = column.getQueryFilterVariables();
    for (var filter in filters) {
      var withInto = '';
      switch (filter.filterClause) {
        case FilterClause.equal:
          if (column.type == ColumnTypeDuckDB.varchar) {
            withInto = '.into()';
            buffer.writeln(
                '\n    pub fn $name<S: Into<String>>(mut self, value: S) -> Self {');
          } else {
            buffer.writeln(
                '\n    pub fn $name(mut self, value: $rustType) -> Self {');
          }
          buffer.writeln('        self.inner.$name = Some(value$withInto);');
          buffer.writeln('        self');
          buffer.writeln('    }');
          break;
        case FilterClause.greaterThanOrEqual:
          buffer.writeln(
              '\n    pub fn ${name}_gte(mut self, value: $rustType) -> Self {');
          buffer.writeln('        self.inner.${name}_gte = Some(value);');
          buffer.writeln('        self');
          buffer.writeln('    }');
          break;
        case FilterClause.lessThanOrEqual:
          buffer.writeln(
              '\n    pub fn ${name}_lte(mut self, value: $rustType) -> Self {');
          buffer.writeln('        self.inner.${name}_lte = Some(value);');
          buffer.writeln('        self');
          buffer.writeln('    }');
          break;
        case FilterClause.like:
          buffer.writeln(
              '\n    pub fn ${column.name}_like(mut self, value_like: String) -> Self {');
          buffer.writeln(
              '        self.inner.${column.name}_like = Some(value_like);');
          buffer.writeln('        self');
          buffer.writeln('    }');
          break;
        case FilterClause.inList:
          buffer.writeln(
              '\n    pub fn ${column.name}_in(mut self, values_in: Vec<$rustType>) -> Self {');
          buffer.writeln(
              '        self.inner.${column.name}_in = Some(values_in);');
          buffer.writeln('        self');
          buffer.writeln('    }');
          break;
      }
    }
  }
  buffer.writeln('}');

  return buffer.toString();
}

String makeTest() {
  final buffer = StringBuffer();

  buffer.writeln('#[cfg(test)]');
  buffer.writeln('mod tests {');
  buffer.writeln('    use std::error::Error;');
  buffer.writeln('    use duckdb::{AccessMode, Config, Connection};');
  buffer.writeln('    use crate::db::prod_db::ProdDb;');
  buffer.writeln('    use super::*;');

  buffer.writeln('\n    #[test]');
  buffer.writeln('    fn test_get_data() -> Result<(), Box<dyn Error>> {');
  buffer.writeln(
      '        let config = Config::default().access_mode(AccessMode::ReadOnly)?;');
  buffer.writeln(
      '        let conn = Connection::open_with_flags(ProdDb::xxx().duckdb_path, config).unwrap();');
  buffer.writeln('        let filter = QueryFilterBuilder::new().build();');
  buffer.writeln(
      '        let xs: Vec<Record> = get_data(&conn, &filter).unwrap();');
  buffer.writeln('        conn.close().unwrap();');
  buffer.writeln('        assert_eq!(xs.len(), 0);');
  buffer.writeln('        Ok(())');
  buffer.writeln('    }');
  buffer.writeln('}');
  return buffer.toString();
}

/// Generate HTML documentation for the query.
String generateHtmlDocs(List<Column> columns) {
  final buffer = StringBuffer();

  buffer.writeln('<p>The url query string has the following components:</p>');
  buffer.writeln('<ul style="list-style-type: circle;">');
  for (var column in columns) {
    final rustType = getRustType(
      type: column.type,
      columnName: column.name,
      isNullable: false,
    );
    final filters = column.getQueryFilterVariables();
    for (var filter in filters) {
      switch (filter.filterClause) {
        case FilterClause.equal:
          buffer.writeln('<li><b>${column.name}</b> $rustType,');
          break;
        case FilterClause.greaterThanOrEqual:
          buffer.writeln('<li><b>${column.name}_gte</b> $rustType,');
          break;
        case FilterClause.lessThanOrEqual:
          buffer.writeln('<li><b>${column.name}_lte</b> $rustType,');
          break;
        case FilterClause.like:
          buffer.writeln('<li><b>${column.name}_like</b> String,');
          break;
        case FilterClause.inList:
          buffer.writeln('<li><b>${column.name}_in</b> Vec<$rustType>,');
          break;
      }
    }
  }
  buffer.writeln('</ul>');

  return buffer.toString();
}
