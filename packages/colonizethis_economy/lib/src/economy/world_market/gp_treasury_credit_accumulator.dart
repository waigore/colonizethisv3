/// Shared per-owning-Great-Power treasury-credit accumulator (Refs #3731).
///
/// Backs the near-identical "per-GP treasury credit" roll-up previously
/// duplicated between First-Right-of-Refusal credits
/// ([first_right_credits.dart], `double`) and purchased-tile riches
/// ([purchased_tile_riches.dart], `int`). It owns the insertion-ordered
/// `byGp` map, maintains the grand total **incrementally** (O(1) read instead
/// of re-summing the map on every access), and exposes an explicit
/// [ensure] op so the FRR audit-trail behavior — recording a `0` entry for an
/// FRR-eligible but zero-profit deal — is preserved exactly.
///
/// Determinism: entries appear in the order each GP id is first seen; the
/// arithmetic is the same integer/double addition as the inline loops it
/// replaces. No logging, RNG, or `Game` access — safe inside the 15-second
/// next-turn-resolution budget per `SPEC/program/turn-resolution-phases.md`
/// § Determinism.
///
/// Intentionally **not** exported from `colonizethis_economy.dart`: an internal
/// seam consumed by the two world-market result helpers only.
library;

/// Insertion-ordered accumulator of treasury credits keyed by owning GP id.
///
/// [T] is the credit's numeric type (`double` for FRR overseas-profit credits,
/// `int` for purchased-tile riches). The accumulator never introduces implicit
/// `dynamic` and never changes precision: it adds `T` deltas and stores `T`
/// values throughout.
class GpTreasuryCreditAccumulator<T extends num> {
  /// Creates an empty accumulator. [zero] is the additive identity for [T]
  /// (`0` for `int`, `0.0` for `double`); it seeds both new map entries and
  /// the running [total].
  GpTreasuryCreditAccumulator(T zero) : _zero = zero, _total = zero;

  final T _zero;
  final Map<String, T> _byGp = <String, T>{};
  T _total;

  /// Adds [delta] to [gpId]'s running credit, creating the entry (from [zero])
  /// on first use, and updates the incrementally-maintained [total].
  void add(String gpId, T delta) {
    _byGp[gpId] = ((_byGp[gpId] ?? _zero) + delta) as T;
    _total = (_total + delta) as T;
  }

  /// Ensures [gpId] has an entry (value [zero]) without changing [total].
  ///
  /// Preserves the FRR zero-profit audit trail: an FRR-eligible deal whose
  /// profit is `0` still records the owning GP so callers can surface every
  /// eligible deal. A no-op when [gpId] already has an entry.
  void ensure(String gpId) {
    _byGp.putIfAbsent(gpId, () => _zero);
  }

  /// Unmodifiable view of the per-GP credits in first-seen insertion order.
  Map<String, T> get view => Map<String, T>.unmodifiable(_byGp);

  /// Running grand total across all GP credits, maintained incrementally so
  /// reads are O(1). Equals the naive `view.values` re-sum, including the
  /// zero-valued [ensure] entries (which contribute `0`).
  T get total => _total;

  /// True when no GP credit has been recorded (via [add] or [ensure]).
  bool get isEmpty => _byGp.isEmpty;
}
