import 'package:elec_server/utils.dart';
part 'lib_duckdb_builder_rust.dart';

/// Supported target languages for code generation.
enum Language {
  dart,
  rust,
}

class CodeGenerator {
  CodeGenerator(
    this.sql, {
    required this.language,
    this.requiredFilters = const [],
    this.timezoneName,
  }) {
    tableName = getTableName(sql);
    columns = getColumns(sql, timezoneName: timezoneName);
  }

  final String sql;
  final Language language;
  final String? timezoneName;
  final List<String> requiredFilters;

  ///
  late final String tableName;
  late final List<Column> columns;

  String generateCode() {
    switch (language) {
      case Language.dart:
        return _generateDartStub();
      case Language.rust:
        return _generateRustStub();
    }
  }

  String _generateDartStub() {
    throw UnimplementedError('Dart stub generation not implemented yet.');
  }

  /// It gets really tedious to manually write Rust structs that correspond to
  /// a DuckDB table schema.  The entire info is already available, so why
  /// not generate the Rust code automatically?
  ///
  /// [sql] is the entire DuckDB CREATE TABLE statement.
  /// [inFilters]
  ///
  /// Given a the [sql], create:
  ///   1. a Rust struct with the appropriate types
  ///   2. the enums for all DuckDB ENUM columns
  ///   3. a function to query the database and return a Vec of the struct
  ///   4. a test stub
  ///
  ///
  /// See the test folder for examples.
  String _generateRustStub() {
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
        final variants = getEnumVariants(column.input);
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

    buffer.write('\n\n');
    buffer.write(makeApiQueryStruct(columns, requiredFilters: requiredFilters));

    return buffer.toString();
  }

  /// Generate HTML documentation for the query.
  /// HTML query parameters use the Rust variable naming convention.
  String generateHtmlDocs() {
    final buffer = StringBuffer();
    buffer
        .writeln('<p>The url query string supports the following filters:</p>');
    buffer.writeln('<p>All filters are optional unless otherwise noted.  '
        'If the amount of data returned is too large, the server will return '
        'an error.</p>');
    buffer.writeln('<ul style="list-style-type: circle;">');
    for (var column in columns) {
      var comments = '';
      if (column.type == ColumnTypeDuckDB.enumType) {
        final variants = getEnumVariants(column.input);
        comments =
            '  Possible values: <span style="font-family: monospace">${variants.map((e) => '"$e"').join(', ')}</span>.';
      }
      if (column.isNullable) {
        comments += '  An explicit value of <span style="font-family: monospace">NULL</span> is accepted.';
      }
      for (var filterClause in column.filterClauses) {
        switch (filterClause) {
          case FilterClause.equal:
            buffer.writeln('  <li><b>${column.name}</b> A filter for matching '
                'exactly one value in column ${column.name}.$comments');
            break;
          case FilterClause.greaterThanOrEqual:
            buffer.writeln(
                '  <li><b>${column.name}_gte</b> A filter for values '
                'greater than or equal to a given value in column ${column.name}.');
            break;
          case FilterClause.lessThan:
            buffer.writeln('  <li><b>${column.name}_lt</b> A filter for values '
                'less than a given value in column ${column.name}.');
            break;
          case FilterClause.lessThanOrEqual:
            buffer.writeln(
                '  <li><b>${column.name}_lte</b> A filter for values '
                'less than or equal to a given value in column ${column.name}.');
            break;
          case FilterClause.like:
            buffer.writeln('  <li><b>${column.name}_like</b> A string pattern '
                'to be used as a SQL like filter for the values in column '
                '${column.name}.');
            break;
          case FilterClause.inList:
            buffer.writeln('  <li><b>${column.name}_in</b> A list of values '
                'separated by commas.  If the values themselves contain commas, '
                'they should be enclosed in double quotes.');
            break;
        }
      }
    }
    buffer.writeln('</ul>');

    return buffer.toString();
  }
}

class Column {
  Column({
    required this.name,
    required this.type,
    required this.isNullable,
    this.timezoneName,
  }) {
    filterClauses = Column.getDefaultFilters(type);
    if (type == ColumnTypeDuckDB.timestamptz) {
      if (timezoneName == null) {
        throw StateError(
            'timezoneName is required for TIMESTAMPTZ columns: $name');
      }
    } else {
      if (timezoneName != null) {
        throw StateError(
            'timezoneName should only be provided for TIMESTAMPTZ columns: $name');
      }
    }
  }
  // In snake case
  final String name;
  final ColumnTypeDuckDB type;
  final bool isNullable;
  late final String? timezoneName;

  late final String input;
  late final List<FilterClause> filterClauses;

  /// Create a Column from a SQL column definition string, e.g. a line like:
  /// ```sql
  /// hour_beginning TIMESTAMPTZ NOT NULL,
  /// lmp DECIMAL(18,5) NOT NULL,
  /// ```
  static Column from(String input, {String? timezoneName}) {
    final type = getColumnType(input);
    return Column(
      name: getColumnName(input),
      type: type,
      isNullable: isColumnNullable(input),
      timezoneName: type == ColumnTypeDuckDB.timestamptz ? timezoneName! : null,
    )..input = input;
  }

  Column copyWith({
    String? name,
    ColumnTypeDuckDB? type,
    bool? isNullable,
    List<FilterClause>? filterClauses,
    String? timezoneName,
  }) {
    return Column(
        name: name ?? this.name,
        type: type ?? this.type,
        isNullable: isNullable ?? this.isNullable,
        timezoneName: timezoneName ?? this.timezoneName);
  }

  /// Get the default filters for a given DuckDB column type.
  static List<FilterClause> getDefaultFilters(ColumnTypeDuckDB type) {
    var filters = switch (type) {
      ColumnTypeDuckDB.boolean => [FilterClause.equal],
      ColumnTypeDuckDB.date ||
      ColumnTypeDuckDB.decimal ||
      ColumnTypeDuckDB.tinyint ||
      ColumnTypeDuckDB.int16 ||
      ColumnTypeDuckDB.int32 ||
      ColumnTypeDuckDB.int64 ||
      ColumnTypeDuckDB.uint8 ||
      ColumnTypeDuckDB.uint16 ||
      ColumnTypeDuckDB.uint32 ||
      ColumnTypeDuckDB.uint64 ||
      ColumnTypeDuckDB.uint128 =>
        [
          FilterClause.equal,
          FilterClause.inList,
          FilterClause.greaterThanOrEqual,
          FilterClause.lessThanOrEqual,
        ],
      ColumnTypeDuckDB.double || ColumnTypeDuckDB.float => [
          FilterClause.greaterThanOrEqual,
          FilterClause.lessThan,
        ],
      ColumnTypeDuckDB.timestamp || ColumnTypeDuckDB.timestamptz => [
          FilterClause.equal,
          FilterClause.greaterThanOrEqual,
          FilterClause.lessThan
        ],
      ColumnTypeDuckDB.enumType => [FilterClause.equal, FilterClause.inList],
      ColumnTypeDuckDB.time => <FilterClause>[],
      ColumnTypeDuckDB.varchar => [
          FilterClause.equal,
          FilterClause.like,
          FilterClause.inList
        ],
    };
    return filters;
  }
}

enum FilterClause {
  equal,
  greaterThanOrEqual,
  lessThanOrEqual,
  lessThan,
  like,
  inList;

  /// Construct the SQL filter clause string for this `Column`.
  String makeFilter(Column column) {
    late final String filterString;
    switch (column.type) {
      case ColumnTypeDuckDB.varchar ||
            ColumnTypeDuckDB.enumType ||
            ColumnTypeDuckDB.timestamptz ||
            ColumnTypeDuckDB.timestamp ||
            ColumnTypeDuckDB.date:
        switch (this) {
          case FilterClause.equal:
            filterString = "AND ${column.name} = '{}'";
            break;
          case FilterClause.like:
            filterString = "AND ${column.name} LIKE '{}'";
            break;
          case FilterClause.inList:
            filterString = "AND ${column.name} IN ('{}')";
            break;
          case FilterClause.greaterThanOrEqual:
            filterString = "AND ${column.name} >= '{}'";
            break;
          case FilterClause.lessThanOrEqual:
            filterString = "AND ${column.name} <= '{}'";
            break;
          case FilterClause.lessThan:
            filterString = "AND ${column.name} < '{}'";
            break;
        }
      default:
        // Numeric types and others
        switch (this) {
          case FilterClause.equal:
            filterString = "AND ${column.name} = {}";
            break;
          case FilterClause.like:
            filterString = "AND ${column.name} LIKE {}";
            break;
          case FilterClause.inList:
            filterString = "AND ${column.name} IN ({})";
            break;
          case FilterClause.greaterThanOrEqual:
            filterString = "AND ${column.name} >= {}";
            break;
          case FilterClause.lessThanOrEqual:
            filterString = "AND ${column.name} <= {}";
            break;
          case FilterClause.lessThan:
            filterString = "AND ${column.name} < {}";
            break;
        }
        break;
    }
    return filterString;
  }
}

/// Parse the SQL input and construct the columns from it.
List<Column> getColumns(String input, {String? timezoneName}) {
  final columns = <Column>[];
  var aux = splitColumnDefinitions(input);
  for (var line in aux) {
    var one = Column.from(line, timezoneName: timezoneName);
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

/// Extract the column name from a column definition string.
/// Require that the column name is in snake case for consistency.
/// [input] is one line of SQL corresponding to a column definition.
///
String getColumnName(String input) {
  final parts = input.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) {
    throw FormatException('Invalid column definition: $input');
  }
  if (parts[0] != parts[0].toSnakeCase()) {
    throw FormatException(
        'Column name must be in snake_case: found "${parts[0]}"');
  }
  return parts[0];
}

ColumnTypeDuckDB getColumnType(String input) {
  final parts = input.trim().split(RegExp(r'\s+'));
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
    case 'UTINYINT' || 'UINT8':
      return ColumnTypeDuckDB.uint8;
    case 'USMALLINT' || 'UINT16':
      return ColumnTypeDuckDB.uint16;
    case 'UINT32' || 'UINTEGER':
      return ColumnTypeDuckDB.uint32;
    case 'UBIGINT' || 'UINT64':
      return ColumnTypeDuckDB.uint64;
    case 'UHUGEINT' || 'UINT128':
      return ColumnTypeDuckDB.uint128;
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
/// The Rust enum variant name will be in Pascal case.
List<String> getEnumVariants(String input) {
  // Split by commas not inside quotes
  final variantList = RegExp(r"'([^']*)'")
      .allMatches(input)
      .map((m) => m.group(1) ?? '')
      .toList();
  return variantList;
}

/// Given a column and a filter clause, return the variable name for the filter.
String getQueryFilterVariableName(Column column,
    {required FilterClause clause, required Language language}) {
  switch (language) {
    case Language.dart:
      return throw UnimplementedError(
          'Dart filter variable name generation not implemented yet.');
    case Language.rust:
      switch (clause) {
        case FilterClause.equal:
          return column.name.toSnakeCase();
        case FilterClause.greaterThanOrEqual:
          return '${column.name.toSnakeCase()}_gte';
        case FilterClause.lessThan:
          return '${column.name.toSnakeCase()}_lt';
        case FilterClause.lessThanOrEqual:
          return '${column.name.toSnakeCase()}_lte';
        case FilterClause.like:
          return '${column.name.toSnakeCase()}_like';
        case FilterClause.inList:
          return '${column.name.toSnakeCase()}_in';
      }
  }
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
  uint128,
  varchar,
  time,
  timestamp,
  timestamptz,
}
