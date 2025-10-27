extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  bool isUpperCase() {
    return this == toUpperCase();
  } 

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
    return replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (Match m) {
      return '${m.group(1)}_${m.group(2)}';
    }).toLowerCase();
  }
}
