extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  bool isUpperCase() {
    return this == toUpperCase();
  }

  /// Converts a string to PascalCase.
  /// Handles strings with spaces, underscores, and hyphens as word separators.
  /// Examples:
  ///   "hello world" -> "HelloWorld"
  ///   "hello_world" -> "HelloWorld"
  ///   "hello-world" -> "HelloWorld"
  String toPascalCase() {
    // Replace common separators with spaces and convert to lowercase
    String formattedInput = replaceAll(RegExp(r'[_-]'), ' ').toLowerCase();

    // Split the string into words
    List<String> words = formattedInput.split(' ');

    // Capitalize the first letter of each word and join them
    String pascalCaseString = words.map((word) {
      if (word.isEmpty) {
        return '';
      }
      return word[0].toUpperCase() + word.substring(1);
    }).join('');

    return pascalCaseString;
  }

  String toSnakeCase() {
    // Insert underscore before every uppercase letter (except at the start), then lowercase
    return replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m.group(1)}_${m.group(2)}',
    )
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (m) => '${m.group(1)}_${m.group(2)}',
        )
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toLowerCase()
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Converts a string from camelCase to UPPER_SNAKE_CASE.
  /// Examples:
  ///   "hello World" -> "HELLO_WORLD"
  ///   "helloWorld" -> "HELLO_WORLD"
  ///   "HelloWorld" -> "HELLO_WORLD"
  ///   "hello_world" -> "HELLO_WORLD"
  String toUpperSnakeCase() {
    return toSnakeCase().toUpperCase();
  }
}
