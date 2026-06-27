/// Purchased-tile riches handoff: per-tile riches credits routed to the
/// owning Great Power during phase 3 Riches-to-treasury.
///
/// SPEC: [SPEC/game/world-market.md § First right of refusal § Riches
/// handoff](../../../../../../SPEC/game/world-market.md) and
/// [SPEC/program/turn-resolution-phase-details.md § Riches to treasury](
/// ../../../../../../SPEC/program/turn-resolution-phase-details.md).
/// Authority: issue [#2991](https://github.com/waigore/colonizethisv3/issues/2991)
/// (subtask C5; parent #2988 Requirement 7).
///
/// When a Great Power has purchased a tile from a Minor or Tribe via the
/// Merchant `purchase_land` work order and that tile's resource is in the
/// riches set (`gold`, `silver`, `gems`, `diamonds`, `spices`), the riches
/// are **not** auto-offered on the world market in phase 13 (riches are
/// excluded from trading). Instead, the per-tile yield converts directly
/// to the **owning GP's** treasury during phase 3 Riches-to-treasury, at
/// `units × richesBasePrice(commodityId) × richesCashMultiplier`
/// (truncated to int).
///
/// The Minor or Tribe is **not** credited (Minors and Tribes never hold
/// treasury per `SPEC/game/factions.md`), and the GP-side extraction
/// pipeline (phase 2) is unchanged: this helper is the only path that
/// extracts riches from purchased tiles still owned by their original
/// Minor or Tribe province.
///
/// The helper is intentionally a pure function:
///
/// - Deterministic for a fixed `(Game, tileMapByRegion, multiplier)`.
/// - No logger calls, no RNG.
/// - Reads only published `WorldState` and tile-map fields; safe inside
///   the 15-second next-turn-resolution budget per
///   `SPEC/program/turn-resolution-phases.md` § Determinism.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../game_lookup_helpers.dart';
import '../tile_extraction_pipeline.dart';
import '../tile_extraction_yield.dart';
import 'gp_treasury_credit_accumulator.dart';
import 'purchased_tile_index.dart';

/// Sentinel town-development cap passed to [computeEffectiveTileYield] from the
/// purchased-tile riches path. The town-cap branches are never entered here
/// (not a capital province, no road-rule/port-town path), so this value is
/// never applied; it stays at the maximum tile yield so any future change that
/// enters a town-cap branch cannot silently clamp purchased-tile riches.
const int _townDevelopmentCapDisabled = 4;

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
  const PurchasedTileRichesResult({
    required this.credits,
    required this.treasuryCreditByGpId,
    int? totalTreasuryCredit,
  }) : _totalTreasuryCredit = totalTreasuryCredit;

  /// Empty result. Returned when the purchased-tile index is empty,
  /// `tileMapByRegion` is empty, or no purchased tile resolves to a
  /// non-zero riches yield.
  static const PurchasedTileRichesResult empty = PurchasedTileRichesResult(
    credits: <PurchasedTileRichesCredit>[],
    treasuryCreditByGpId: <String, int>{},
  );

  /// Precomputed grand total from the shared accumulator, when constructed via
  /// [computePurchasedTileRichesCredits]. `null` for hand-built results (for
  /// example the [empty] sentinel), which fall back to summing
  /// [treasuryCreditByGpId].
  final int? _totalTreasuryCredit;

  /// Per-tile credit records (same order as
  /// [PurchasedTileIndex.attributions]).
  final List<PurchasedTileRichesCredit> credits;

  /// Treasury-delta credits to add to each owning Great Power's
  /// treasury. Insertion order matches the order in which each owning
  /// GP first appears in [credits].
  final Map<String, int> treasuryCreditByGpId;

  /// Convenience: total treasury credited across every owning GP for
  /// this aggregation.
  ///
  /// O(1) when produced by [computePurchasedTileRichesCredits] (the
  /// [GpTreasuryCreditAccumulator] maintains the total incrementally); falls
  /// back to re-summing [treasuryCreditByGpId] for hand-built results.
  int get totalTreasuryCredit {
    final cached = _totalTreasuryCredit;
    if (cached != null) return cached;
    var total = 0;
    for (final amount in treasuryCreditByGpId.values) {
      total += amount;
    }
    return total;
  }

  bool get isEmpty => credits.isEmpty;
  bool get isNotEmpty => credits.isNotEmpty;
}

/// Computes per-tile riches credits for purchased Minor and Tribe tiles.
///
/// For every entry in `purchasedTileIndex` whose tile resource is in
/// [richesCommodityIds] and whose effective per-tile yield is `> 0`,
/// this function emits a [PurchasedTileRichesCredit] keyed to the
/// owning Great Power.
///
/// The per-tile yield uses the published `Game.worldState.tileState`
/// fields:
///
/// ```
/// production         = min(improvementLevel, defaultExtractionCap)  // ∈ [0, 1]
/// tileTransportLevel = port ? 4 : roadLevel                          // ∈ [0, 4]
/// effective          = min(production, tileTransportLevel)            // ∈ [0, 1]
/// ```
///
/// Tiles with `improvementLevel == 0`, `tileTransportLevel == 0`, or
/// missing tile-map / resource entries return zero and are filtered
/// out. The mineral-prospecting filter that excludes
/// `gold/silver/gems/diamonds` from regular non-Great-Power extraction
/// is **bypassed** here because the owning Great Power's purchase
/// authorizes the riches yield (see SPEC § Riches handoff).
///
/// Returns [PurchasedTileRichesResult.empty] when [purchasedTileIndex]
/// is empty, [tileMapByRegion] is empty, or no eligible tile produces
/// a non-zero credit.
PurchasedTileRichesResult computePurchasedTileRichesCredits({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required PurchasedTileIndex purchasedTileIndex,
  double richesCashMultiplier = 1.0,
}) {
  if (purchasedTileIndex.isEmpty || tileMapByRegion.isEmpty) {
    return PurchasedTileRichesResult.empty;
  }

  final portTileKeys = collectPortTileKeys(game);
  final tileState = game.worldState.tileState;

  final credits = <PurchasedTileRichesCredit>[];
  final treasuryByGp = GpTreasuryCreditAccumulator<int>(0);

  // Sort attributions by tileKey for deterministic emission order
  // independent of the index's underlying map iteration order.
  final attributions = purchasedTileIndex.attributions.toList()
    ..sort((a, b) => a.tileKey.compareTo(b.tileKey));

  for (final attribution in attributions) {
    final tileKey = attribution.tileKey;
    final resourceContext = resolveTileKeyResourceContext(
      tileKey: tileKey,
      tileMapByRegion: tileMapByRegion,
    );
    if (resourceContext == null) continue;

    final commodityId = resourceContext.commodityId;
    if (!richesCommodityIds.contains(commodityId)) continue;

    final basePrice = richesBasePrice(commodityId);
    if (basePrice <= 0) continue;

    // Purchased-tile riches deliberately skip the town-development cap: the
    // owning GP's purchase authorizes the yield independent of the source
    // province's town development (see SPEC § Riches handoff). The shared
    // [computeEffectiveTileYield] math is reused with the town-cap branches
    // disabled (not capital, no road-rule/port-town path) and an empty
    // `pathTransportCap` so the per-tile transport level governs the cap.
    final effective = computeEffectiveTileYield(
      tileState: tileState,
      tileKey: tileKey,
      techCap: defaultExtractionCap,
      townDevelopmentCap: _townDevelopmentCapDisabled,
      townTileIsPort: false,
      isCapitalProvince: false,
      usesRoadRule: false,
      portTileKeys: portTileKeys,
      pathTransportCap: const <String, int>{},
    );
    if (effective <= 0) continue;

    final treasuryDelta = (effective * basePrice * richesCashMultiplier)
        .truncate();
    if (treasuryDelta <= 0) continue;

    credits.add(
      PurchasedTileRichesCredit(
        tileKey: tileKey,
        owningGpId: attribution.owningGpId,
        sourceFactionId: attribution.sourceFactionId,
        commodityId: commodityId,
        units: effective,
        treasuryDelta: treasuryDelta,
      ),
    );
    treasuryByGp.add(attribution.owningGpId, treasuryDelta);
  }

  if (credits.isEmpty) return PurchasedTileRichesResult.empty;
  return PurchasedTileRichesResult(
    credits: List<PurchasedTileRichesCredit>.unmodifiable(credits),
    treasuryCreditByGpId: treasuryByGp.view,
    totalTreasuryCredit: treasuryByGp.total,
  );
}
