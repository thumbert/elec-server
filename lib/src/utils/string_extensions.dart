library utils.string_extensions;

extension StringExtensions on String {
  String capitalize(String x) {
    if (x.isEmpty) return x;
    return x[0].toUpperCase() + x.substring(1);
  }
}