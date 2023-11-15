library utils.list_extensions;

extension IterableExtensions<E> on Iterable<E> {
  /// Partition an iterable based on a condition.
  /// First element (left) is the true condition, the second element (right)
  /// is the false condition.
  (List<E>, List<E>) partition(bool Function(E) predicate) {
    final left = <E>[];
    final right = <E>[];
    for (var e in this) {
      if (predicate(e)) {
        left.add(e);
      } else {
        right.add(e);
      }
    }
    return (left, right);
  }

}