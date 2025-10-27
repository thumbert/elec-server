import 'package:elec_server/utils.dart';
part 'lib_duckdb_builder_rust.dart';

/// It gets really tedious to manually write Rust structs that correspond to
/// a DuckDB table schema.  The entire info is already available, so why
/// not generate the Rust code automatically?
///
/// Given a DuckDB CREATE TABLE statement as input,
/// generates a Rust struct stub representing the table schema, etc.
/// This includes:
///  - creating the enums for any columns that are ENUM in DuckDB
///  - generating a function that will query the database and return a Vec of
///    the struct
///  - generating a test stub
///
/// [input] is the DuckDB CREATE TABLE statement.
///
/// See the test folder for examples.
String generateRustStub(String input,
    {List<String> likeFilters = const <String>[],
    List<String> inFilters = const <String>[],
    String? timezoneName}) {
  final tableName = getTableName(input);
  final columns =
      getColumns(input, likeFilters: likeFilters, inFilters: inFilters);

  final buffer = StringBuffer();
  buffer.writeln('// Auto-generated Rust stub for DuckDB table: $tableName');
  buffer.writeln(
      '// Created on ${DateTime.now().toIso8601String().substring(0, 10)} '
      'with elec_server/utils/lib_duckdb_builder.dart\n');
  buffer.write(addImports(columns));

  buffer.write('\n');
  buffer.write(makeStruct(columns));

  for (var column in columns) {
    if (column.type == ColumnTypeDuckDB.enumType) {
      final variants = getEnumVariants(column.line);
      variants.sort();
      buffer.write('\n');
      buffer.write(makeEnum(
          columnName: column.name,
          values: variants,
          isNullable: column.isNullable));
    }
  }

  buffer.write('\n');
  buffer.write(makeQueryFunction(tableName, columns));

  buffer.write('\n');
  buffer.write(makeQueryFilterStruct(columns));

  buffer.write('\n');
  buffer.write(makeQueryFilterBuilder(columns));

  buffer.write('\n\n');
  buffer.write(makeTest());

  return buffer.toString();
}

class Column {
  Column(
      {required this.name,
      required this.type,
      required this.isNullable,
      required this.line});
  final String name;
  final ColumnTypeDuckDB type;
  final bool isNullable;
  final String line;

  // Not sure about having these flags here, but let's see how it holds up
  // These fields should be private, but I can't test Column without them.
  // Very annoying, Dart!
  bool hasInFilter = false;
  bool hasLikeFilter = false;
  bool hasGteFilter = false;
  bool hasLteFilter = false;
  String? timezoneName;

  /// Sometimes one variable in the Record struct will have multiple filter
  /// variables. For example, an `as_of: Date` field will have in addition
  /// to the simple equality filter, an gte and lte filter variable.
  ///
  List<QueryFilterVariable> getQueryFilterVariables() {
    final variables = <QueryFilterVariable>[];
    final rustType =
        getRustType(type: type, columnName: name, isNullable: isNullable);

    // Equal filter, always present
    variables.add(QueryFilterVariable(
      rustVariableName: name.toSnakeCase(),
      rustType: rustType,
      filterClause: FilterClause.equal,
    ));

    // Like filter
    if (hasLikeFilter) {
      variables.add(QueryFilterVariable(
        rustVariableName: '${name.toSnakeCase()}_like',
        rustType: rustType,
        filterClause: FilterClause.like,
      ));
    }

    // In filter
    if (hasInFilter) {
      variables.add(QueryFilterVariable(
        rustVariableName: '${name.toSnakeCase()}_in',
        rustType:
            'Vec<${rustType.replaceAll("Option<", "").replaceAll(">", "")}>',
        filterClause: FilterClause.inList,
      ));
    }

    // Greater than or equal filter
    if (hasGteFilter) {
      variables.add(QueryFilterVariable(
        rustVariableName: '${name.toSnakeCase()}_gte',
        rustType: rustType,
        filterClause: FilterClause.greaterThanOrEqual,
      ));
    }

    // Less than or equal filter
    if (hasLteFilter) {
      variables.add(QueryFilterVariable(
        rustVariableName: '${name.toSnakeCase()}_lte',
        rustType: rustType,
        filterClause: FilterClause.lessThanOrEqual,
      ));
    }

    return variables;
  }
}

class QueryFilterVariable {
  QueryFilterVariable({
    required this.rustVariableName,
    required this.rustType,
    required this.filterClause,
  });
  final String rustVariableName;
  final String rustType;
  final FilterClause filterClause;

  String getFilterClause() {
    switch (filterClause) {
      case FilterClause.equal:
        return "AND $rustVariableName = '{}'";
      case FilterClause.greaterThanOrEqual:
        return "AND $rustVariableName >= '{}'";
      case FilterClause.lessThanOrEqual:
        return "AND $rustVariableName <= '{}'";
      case FilterClause.like:
        return "AND $rustVariableName LIKE '{}'";
      case FilterClause.inList:
        if (rustType == 'String') {
          // probably other types in this bucket too, e.g. enums.
          return "AND $rustVariableName IN ('{}')";
        } else {
          return "AND $rustVariableName IN ({})";
        }
    }
  }
}

enum FilterClause {
  equal,
  greaterThanOrEqual,
  lessThanOrEqual,
  like,
  inList,
}

/// Parse the SQL input and construct the columns from it.
List<Column> getColumns(String input,
    {List<String> likeFilters = const <String>[],
    List<String> inFilters = const <String>[],
    String? timezoneName}) {
  final columns = <Column>[];
  var aux = splitColumnDefinitions(input);
  for (var line in aux) {
    var one = Column(
      name: getColumnName(line),
      type: getColumnType(line),
      isNullable: isColumnNullable(line),
      line: line,
    );
    if (one.type == ColumnTypeDuckDB.timestamptz) {
      one.timezoneName = timezoneName!;
    }
    if (likeFilters.contains(one.name) &&
        one.type == ColumnTypeDuckDB.varchar) {
      one.hasLikeFilter = true;
    }
    if (inFilters.contains(one.name)) {
      one.hasInFilter = true;
    }
    if (one.type == ColumnTypeDuckDB.date ||
        one.type == ColumnTypeDuckDB.timestamp ||
        one.type == ColumnTypeDuckDB.timestamptz) {
      one.hasGteFilter = true;
      one.hasLteFilter = true;
    }
    columns.add(one);
  }

  return columns;
}

/// Splits the column definitions from a CREATE TABLE statement into individual
/// column definition strings, potentially collapsing multiple lines into one.
List<String> splitColumnDefinitions(String sql) {
  // Extract the block inside parentheses after CREATE TABLE
  final tableDefMatch =
      RegExp(r'CREATE TABLE.*?\((.*)\)', dotAll: true).firstMatch(sql);
  if (tableDefMatch == null) return [];
  final columnsBlock = tableDefMatch.group(1)!;

  // Split on commas not inside parentheses (handles multi-line and enums)
  final splitter = RegExp(r',(?![^(]*\))');
  return columnsBlock
      .split(splitter)
      .map(
          (s) => s.trim().replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' '))
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Extract the table name from a CREATE TABLE statement.
String getTableName(String input) {
  final match =
      RegExp(r'CREATE TABLE(?: IF NOT EXISTS)?\s+(\w+)', caseSensitive: false)
          .firstMatch(input);
  if (match != null) {
    return match.group(1)!;
  } else {
    throw FormatException('Could not find table name in input.');
  }
}

String getColumnName(String input) {
  final parts = input.split(RegExp(r'\s+'));
  if (parts.length < 2) {
    throw FormatException('Invalid column definition: $input');
  }
  return parts[0];
}

ColumnTypeDuckDB getColumnType(String input) {
  final parts = input.split(RegExp(r'\s+'));
  if (parts.length < 2) {
    throw FormatException('Invalid column definition: $input');
  }
  var typeString = parts[1].toUpperCase();
  // remove a potentially existing comma at the end of the name
  typeString = typeString.replaceAll(',', '');
  // Handle types with parameters, e.g., VARCHAR(255), DECIMAL(10,2), ENUM('a','b')
  if (typeString.contains('(')) {
    typeString = typeString.split('(').first;
  }
  switch (typeString) {
    case 'BOOLEAN':
      return ColumnTypeDuckDB.boolean;
    case 'DATE':
      return ColumnTypeDuckDB.date;
    case 'DECIMAL': // handle multiple widths, scales
      return ColumnTypeDuckDB.decimal;
    case 'DOUBLE':
      return ColumnTypeDuckDB.double;
    case 'TINYINT' || 'INT1':
      return ColumnTypeDuckDB.tinyint;
    case 'SMALLINT' || 'INT2' || 'INT16' || 'SHORT':
      return ColumnTypeDuckDB.int16;
    case 'INT' || 'INTEGER' || 'INT4' || 'INT32':
      return ColumnTypeDuckDB.int32;
    case 'BIGINT' || 'INT8' || 'INT64' || 'LONG':
      return ColumnTypeDuckDB.int64;
    case 'ENUM':
      return ColumnTypeDuckDB.enumType;
    case 'FLOAT':
    case 'FLOAT4':
    case 'FLOAT8':
      return ColumnTypeDuckDB.float;
    case 'UTINYINT':
      return ColumnTypeDuckDB.uint8;
    case 'USMALLINT':
      return ColumnTypeDuckDB.uint16;
    case 'UINT':
    case 'UINTEGER':
      return ColumnTypeDuckDB.uint32;
    case 'UBIGINT':
      return ColumnTypeDuckDB.uint64;
    case 'VARCHAR' || 'CHAR' || 'STRING' || 'TEXT':
      return ColumnTypeDuckDB.varchar;
    case 'TIMESTAMP' || 'TIMESTAMP WITHOUT TIME ZONE' || 'DATETIME':
      return ColumnTypeDuckDB.timestamp;
    case 'TIMESTAMPTZ' || 'TIMESTAMP WITH TIME ZONE':
      return ColumnTypeDuckDB.timestamptz;
    default:
      throw UnsupportedError('Unsupported column type: $typeString');
  }
}

bool isColumnNullable(String input) {
  final upperLine = input.toUpperCase();
  if (upperLine.contains('NOT NULL')) {
    return false;
  } else {
    return true;
  }
}

/// Extract the enum variants for a given column.
/// [input] is one row.
///
List<String> getEnumVariants(String input) {
  // Split by commas not inside quotes
  final variantList = RegExp(r"'([^']*)'")
      .allMatches(input)
      .map((m) => m.group(1) ?? '')
      .toList();
  return variantList;
}

enum ColumnTypeDuckDB {
  boolean,
  date,
  decimal,
  double,
  tinyint,
  int16,
  int32,
  int64,
  enumType,
  float,
  uint8,
  uint16,
  uint32,
  uint64,
  varchar,
  time,
  timestamp,
  timestamptz,
}
