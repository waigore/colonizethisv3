/// Shared utility for **per-instance** lazily computed values cached on an
/// [Expando]. Refs #2836 item 1 (ExpandoIndex utility).
///
/// `ExpandoIndex<K, V>` wraps the recurring "look up a value derived from `K`
/// — build on first access, reuse on later accesses, GC'd when `K` becomes
/// unreachable" pattern used by `province_lookup`, `unit_lookup`,
/// `topology_helpers`, `naval`, `civilian_tile_occupancy`, and similar
/// `colonizethis_logic` hot paths. Centralising the pattern gives:
///
///   * one shared invalidation contract (cache lives with the key object;
///     GC frees both together);
///   * one canonical lazy-build call site so future tweaks (debug logging,
///     metrics) land in a single place;
///   * a single named `Expando` per cache (no anonymous Expandos littered
///     through `lib/src`).
///
/// `K extends Object` enforces a non-nullable key (Expandos cannot key off
/// `null`); `V extends Object` enforces a non-nullable value so the
/// `Expando[key] == null` sentinel cleanly means "not yet computed". Both
/// constraints mirror what the migrated call sites already required.
///
/// SPEC: this is internal infrastructure — no game/AI behaviour change. The
/// migration is structural (Refs #2836 AC 1).
library;

/// Lazily computed value of type `V` cached per `K` instance via [Expando].
///
/// Typical use:
///
/// ```dart
/// final _provinceById = ExpandoIndex<List<Province>, Map<String, Province>>(
///   'provinceByIdForProvinceList',
///   (provinces) => {for (final p in provinces) p.id: p},
/// );
///
/// Map<String, Province> indexFor(List<Province> provinces) =>
///     _provinceById.get(provinces);
/// ```
///
/// The cached value is built once per `K` instance and reused on every later
/// `get(key)` call until the key is garbage collected. `[builder]` must be a
/// pure function of `key` (same `K` instance produces the same `V`).
class ExpandoIndex<K extends Object, V extends Object> {
  ExpandoIndex(String debugName, V Function(K key) builder)
    : _expando = Expando<V>(debugName),
      _builder = builder;

  final Expando<V> _expando;
  final V Function(K key) _builder;

  /// Returns the cached value for [key], building it on first access.
  V get(K key) {
    final cached = _expando[key];
    if (cached != null) return cached;
    final built = _builder(key);
    _expando[key] = built;
    return built;
  }

  /// Reads the cached value for [key] without building. Returns null when the
  /// value has not been computed yet (or has been GC'd alongside [key]).
  ///
  /// Useful for cases that want to peek at the cache for an optimistic
  /// fast-path (for example a per-region nested cache where the outer entry
  /// may exist while a specific inner key is still missing).
  V? peek(K key) => _expando[key];

  /// Stores [value] as the cached entry for [key], replacing any earlier
  /// value. Used by callers that compute the value via a separate path (for
  /// example two-level region-keyed caches that fill the inner map
  /// progressively).
  void put(K key, V value) {
    _expando[key] = value;
  }
}
