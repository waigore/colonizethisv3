/// Shared pre-phase snapshot helpers for turn-resolution phase handlers.
///
/// Phase handlers capture a keyed before-state, run the phase, then diff the
/// after-state to emit events. This collapses the repeated imperative
/// "build a before-map" loop into a single declarative projection so each
/// phase only states its key/value mapping. Refs #3701.
library;

/// Builds a snapshot map over [items], keyed by [key] with values from [value].
///
/// Iterates [items] exactly once and preserves iteration order for repeated
/// keys (last write wins), matching the previous inline build loops so
/// turn-resolution determinism is unchanged.
Map<K, V> snapshotBy<T, K, V>(
  Iterable<T> items,
  K Function(T item) key,
  V Function(T item) value,
) {
  final result = <K, V>{};
  for (final item in items) {
    result[key(item)] = value(item);
  }
  return result;
}
