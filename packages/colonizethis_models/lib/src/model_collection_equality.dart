/// Shared collection equality for model `==` implementations.
///
/// Single source of truth for list/map/set value equality across
/// `colonizethis_models` (Refs #4068). Order-sensitive for lists; map equality
/// requires matching keys and `==` on values; set equality is membership-based.
library;

/// Returns true when [a] and [b] have the same length and pairwise `==` elements.
bool modelListEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns true when [a] and [b] have the same keys and equal values per key.
bool modelMapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

/// Nullable-map variant: both null is equal; otherwise delegates to [modelMapEquals].
bool modelNullableMapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return modelMapEquals(a, b);
}

/// Returns true when [a] and [b] contain the same members (order-independent).
bool modelSetEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}

/// Map-of-list equality: same keys and [modelListEquals] on each value list.
bool modelMapOfListEquals<K, V>(Map<K, List<V>> a, Map<K, List<V>> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null || !modelListEquals(entry.value, other)) {
      return false;
    }
  }
  return true;
}

/// Nullable map-of-list variant used by [Game] color-override equality.
bool modelNullableMapOfListEquals<K, V>(
  Map<K, List<V>>? a,
  Map<K, List<V>>? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return modelMapOfListEquals(a, b);
}
