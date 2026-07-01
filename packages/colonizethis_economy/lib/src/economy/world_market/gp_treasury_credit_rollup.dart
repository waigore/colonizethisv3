/// Shared per-owning-Great-Power treasury roll-up result fields (Refs #3831).
///
/// Backs the near-identical structural contract between
/// [FirstRightCreditsResult] (`double` credits) and
/// [PurchasedTileRichesResult] (`int` credits): insertion-ordered
/// `treasuryCreditByGpId`, optional precomputed grand total from
/// [GpTreasuryCreditAccumulator], and a fallback re-sum getter.
///
/// Intentionally **not** exported from `colonizethis_economy.dart`: an internal
/// seam consumed by the two world-market result helpers only.
library;

import 'gp_treasury_credit_accumulator.dart';

/// Insertion-ordered per-GP treasury credit roll-up with an optional cached
/// grand total.
class GpTreasuryCreditRollup<T extends num> {
  const GpTreasuryCreditRollup({
    required this.treasuryCreditByGpId,
    T? cachedGrandTotal,
  }) : _cachedGrandTotal = cachedGrandTotal;

  /// Builds a roll-up from a completed [GpTreasuryCreditAccumulator].
  factory GpTreasuryCreditRollup.fromAccumulator(
    GpTreasuryCreditAccumulator<T> accumulator,
  ) => GpTreasuryCreditRollup(
    treasuryCreditByGpId: accumulator.view,
    cachedGrandTotal: accumulator.total,
  );

  final Map<String, T> treasuryCreditByGpId;
  final T? _cachedGrandTotal;

  /// O(1) when produced from [GpTreasuryCreditAccumulator] (or otherwise
  /// constructed with [cachedGrandTotal]); falls back to re-summing
  /// [treasuryCreditByGpId] for hand-built results such as `empty` sentinels.
  T grandTotal(T zero) {
    final cached = _cachedGrandTotal;
    if (cached != null) return cached;
    var total = zero;
    for (final amount in treasuryCreditByGpId.values) {
      total = (total + amount) as T;
    }
    return total;
  }
}
