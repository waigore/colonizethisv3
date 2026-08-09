/// Per-tile and aggregated result types for purchased-tile riches credits.
///
/// SPEC: [SPEC/game/world-market.md § First right of refusal § Riches handoff](
/// ../../../../../../SPEC/game/world-market.md). Authority: issue
/// [#2991](https://github.com/waigore/colonizethisv3/issues/2991); phase-8 type
/// extraction Refs #4299.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'gp_treasury_credit_rollup.dart';

/// Per-tile riches credit produced by [computePurchasedTileRichesCredits].
///
/// Credits are emitted in the iteration order of
/// [PurchasedTileIndex.attributions] (tile-key insertion order); callers
/// that need byte-stable order should read [tileKey] and re-sort.
class PurchasedTileRichesCredit {
  const PurchasedTileRichesCredit({
    required this.tileKey,
    required this.owningGpId,
    required this.sourceFactionId,
    required this.commodityId,
    required this.units,
    required this.treasuryDelta,
  });

  /// Tile-key whose riches resource produced [units] this turn.
  final String tileKey;

  /// Great Power id that previously executed `purchase_land` on
  /// [tileKey]. Treasury is credited to this GP, not to the Minor or
  /// Tribe that owns the underlying province.
  final String owningGpId;

  /// Current Minor or Tribe id that owns the province containing
  /// [tileKey]. Recorded for audit / observer-trace purposes only —
  /// the helper never credits this faction.
  final String sourceFactionId;

  /// Riches commodity extracted on this turn (member of
  /// `richesCommodityIds`).
  final CommodityId commodityId;

  /// Effective per-tile yield in commodity units, computed as
  /// `min(improvementLevel, defaultExtractionCap, tileTransportLevel)`
  /// clamped to `[0, 4]`. Always `> 0` for emitted credits — zero-yield
  /// tiles are filtered out at construction time so callers do not need
  /// to defensively skip them.
  final int units;

  /// Treasury units credited to [owningGpId] for this tile, equal to
  /// `(units * richesBasePrice(commodityId) * richesCashMultiplier).truncate()`.
  /// Always `> 0` for emitted credits.
  final int treasuryDelta;

  @override
  String toString() =>
      'PurchasedTileRichesCredit(tile: $tileKey, owningGp: $owningGpId, '
      'source: $sourceFactionId, commodity: $commodityId, units: $units, '
      'treasuryDelta: $treasuryDelta)';
}

/// Aggregated result of [computePurchasedTileRichesCredits].
///
/// [credits] preserves the per-tile audit trail in
/// [PurchasedTileIndex.attributions] iteration order (tile-key insertion
/// order). [treasuryCreditByGpId] is the per-GP roll-up the
/// riches-to-treasury phase handler applies on top of each GP's regular
/// stockpile-driven cash-in.
class PurchasedTileRichesResult {
  PurchasedTileRichesResult({
    required this.credits,
    required Map<String, int> treasuryCreditByGpId,
    int? totalTreasuryCredit,
  }) : _rollup = GpTreasuryCreditRollup<int>(
         treasuryCreditByGpId: treasuryCreditByGpId,
         cachedGrandTotal: totalTreasuryCredit,
       );

  /// Empty result. Returned when the purchased-tile index is empty,
  /// `tileMapByRegion` is empty, or no purchased tile resolves to a
  /// non-zero riches yield.
  static final PurchasedTileRichesResult empty = PurchasedTileRichesResult(
    credits: <PurchasedTileRichesCredit>[],
    treasuryCreditByGpId: <String, int>{},
  );

  final GpTreasuryCreditRollup<int> _rollup;

  /// Per-tile credit records (same order as
  /// [PurchasedTileIndex.attributions]).
  final List<PurchasedTileRichesCredit> credits;

  /// Treasury-delta credits to add to each owning Great Power's
  /// treasury. Insertion order matches the order in which each owning
  /// GP first appears in [credits].
  Map<String, int> get treasuryCreditByGpId => _rollup.treasuryCreditByGpId;

  /// Convenience: total treasury credited across every owning GP for
  /// this aggregation.
  ///
  /// O(1) when produced by [computePurchasedTileRichesCredits] (the
  /// [GpTreasuryCreditAccumulator] maintains the total incrementally); falls
  /// back to re-summing [treasuryCreditByGpId] for hand-built results.
  int get totalTreasuryCredit => _rollup.grandTotal(0);

  bool get isEmpty => credits.isEmpty;
  bool get isNotEmpty => credits.isNotEmpty;
}
