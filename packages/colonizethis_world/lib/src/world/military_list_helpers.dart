/// Shared mechanical list/id partition helpers for army and fleet commands
/// (Refs #3968). Policy (home-container retain-when-empty, ownership checks)
/// stays in the command entrypoints; these helpers only split collections.

/// Partitions [items] into selected vs remaining by [selectedIds] using [idOf].
({List<T> selected, List<T> remaining}) partitionBySelectedIds<T>({
  required Iterable<T> items,
  required Set<String> selectedIds,
  required String Function(T item) idOf,
}) {
  final selected = <T>[];
  final remaining = <T>[];
  for (final item in items) {
    if (selectedIds.contains(idOf(item))) {
      selected.add(item);
    } else {
      remaining.add(item);
    }
  }
  return (selected: selected, remaining: remaining);
}

/// Returns ids from [allIds] that are not in [removeIds], preserving order.
List<String> idsNotIn(List<String> allIds, Set<String> removeIds) =>
    allIds.where((id) => !removeIds.contains(id)).toList();

/// Replaces the entry with [id] in [items] (matched via [idOf]) with
/// [replacement], preserving order. When no match, returns a copy of [items].
List<T> replaceById<T>({
  required List<T> items,
  required String id,
  required T replacement,
  required String Function(T item) idOf,
}) => [
  for (final item in items)
    if (idOf(item) == id) replacement else item,
];
