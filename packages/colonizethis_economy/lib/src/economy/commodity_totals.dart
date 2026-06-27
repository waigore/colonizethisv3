/// Library-internal integer-map accumulation and value-sum helpers (Refs
/// #3731).
///
/// These tiny pure functions centralize the two arithmetic micro-idioms that
/// were re-written inline across the economy package's extraction, production,
/// transport, and world-market helpers:
///
/// - the `m[k] = (m[k] ?? 0) + v` accumulation idiom, and
/// - the `iterable.fold<int>(0, (a, b) => a + b)` value-sum idiom (including
///   the nested map-of-maps sum used by the extraction debug logs).
///
/// They preserve the exact integer arithmetic and insertion order of the
/// original inline call sites, stay allocation-neutral, and perform no logging
/// or `Game` access, so they remain safe inside the 15-second
/// next-turn-resolution budget per `SPEC/program/turn-resolution-phases.md`
/// § Determinism.
///
/// Intentionally **not** exported from `colonizethis_economy.dart`: this is an
/// internal seam, consumed only by sibling `lib/src/economy/**` sources.
library;

/// Adds [delta] to the running integer total for [key] in [into], creating the
/// entry (starting from `0`) on first use.
///
/// Equivalent to the inline `into[key] = (into[key] ?? 0) + delta;` idiom, with
/// identical insertion-order semantics (a key first seen here is appended in
/// encounter order). Callers keep their own positivity/skip guards (for example
/// `if (delta <= 0) continue;`) — this helper does not filter.
void addUnits<K>(Map<K, int> into, K key, int delta) {
  into[key] = (into[key] ?? 0) + delta;
}

/// Sums [values] as integers, returning `0` for an empty iterable.
///
/// Equivalent to `values.fold<int>(0, (a, b) => a + b)`.
int sumValues(Iterable<int> values) {
  var total = 0;
  for (final v in values) {
    total += v;
  }
  return total;
}

/// Sums every integer value across the nested [maps], returning `0` when there
/// are no entries.
///
/// Equivalent to `maps.fold<int>(0, (s, m) => s + sumValues(m.values))`; used by
/// the extraction debug-log roll-ups that total a `Map<_, Map<_, int>>`.
int sumNestedValues<K>(Iterable<Map<K, int>> maps) {
  var total = 0;
  for (final m in maps) {
    total += sumValues(m.values);
  }
  return total;
}
