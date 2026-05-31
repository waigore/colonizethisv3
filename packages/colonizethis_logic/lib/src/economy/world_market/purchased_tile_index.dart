/// Purchased-tile attribution index for World Market First Right of Refusal.
///
/// SPEC: [SPEC/game/world-market-first-right-of-refusal.md § Purchased-tile
/// index (D1)](../../../../../../SPEC/game/world-market-first-right-of-refusal.md).
/// Authority: issue [#2992](https://github.com/waigore/colonizethisv3/issues/2992)
/// (D1 subtask).
///
/// The index joins the three on-dev data sources that D2/D4 callers need
/// to credit the First Right of Refusal overseas-profit cut per filled
/// deal:
///
/// 1. `WorldState.purchasedTilesByTileKey` — `tileKey → buyer (owning) GP id`
///    written by the `purchase_land` work completion handler.
/// 2. `WorldState.tileKeysByRegionAndProvince` — region/province → tile
///    list, used to resolve the province that contains each purchased
///    tile.
/// 3. `Province.ownerId` — the **current** owner of the containing
///    province. The purchased-tile mechanic only fires when this owner is
///    a minor or tribe; entries where the province has been conquered by
///    a Great Power are filtered out so FRR cannot be credited on
///    GP-on-GP sales.
///
/// The index is built eagerly per call and exposes a single per-tile
/// lookup plus a snapshot iterable. It is intentionally a pure helper
/// (no logger calls, no RNG) so it stays safely callable from hot
/// turn-resolution paths inside the 15-second next-turn budget per
/// `SPEC/program/turn-resolution-phases.md` § Determinism.
library;

import 'package:colonizethis_models/colonizethis_models.dart' show Game;

import '../../diplomacy/diplomacy_resolver.dart'
    show DiplomacyFactionMembership;
import '../../world/province_lookup.dart' show WorldStateProvinceLookup;

/// Per-tile attribution record returned by [PurchasedTileIndex].
///
/// A record describes one tile key that was previously purchased by a
/// Great Power from the **current** minor or tribe owner of the
/// containing province. The fields are the minimum set D2 (priority
/// override) and D4 (treasury transfer) callers need without re-querying
/// the world state per deal.
class PurchasedTileAttribution {
  const PurchasedTileAttribution({
    required this.tileKey,
    required this.owningGpId,
    required this.sourceFactionId,
    required this.provinceId,
  });

  /// Tile-key whose offers attribute to a purchased-land contract.
  /// Matches the keys stored in `WorldState.purchasedTilesByTileKey`.
  final String tileKey;

  /// Great Power id that previously executed `purchase_land` on this
  /// tile. This GP receives the First Right of Refusal credit when a
  /// **different** GP buys offers backed by the tile.
  final String owningGpId;

  /// Current minor or tribe id that owns the province containing
  /// [tileKey]. Used by D3's [computeFirstRightProfit] to look up the
  /// hidden 0–100 relation score between [owningGpId] and the source
  /// faction.
  final String sourceFactionId;

  /// Full prefixed province id (`regionId|localId`) of the province
  /// containing [tileKey].
  final String provinceId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchasedTileAttribution &&
        other.tileKey == tileKey &&
        other.owningGpId == owningGpId &&
        other.sourceFactionId == sourceFactionId &&
        other.provinceId == provinceId;
  }

  @override
  int get hashCode =>
      Object.hash(tileKey, owningGpId, sourceFactionId, provinceId);

  @override
  String toString() =>
      'PurchasedTileAttribution(tile: $tileKey, owningGp: $owningGpId, '
      'source: $sourceFactionId, province: $provinceId)';
}

/// Eagerly built per-[Game] index of purchased-tile attributions.
///
/// Use [PurchasedTileIndex.fromGame] once per world-market resolution
/// pass; the resulting object is immutable and safe to share across the
/// deal-match inner loop.
class PurchasedTileIndex {
  const PurchasedTileIndex._(this._byTileKey);

  /// Builds the index from the current [Game] state. Entries whose
  /// containing province is no longer owned by a minor or tribe are
  /// filtered out (see class-level documentation).
  factory PurchasedTileIndex.fromGame(Game game) {
    final purchasedTiles = game.worldState.purchasedTilesByTileKey;
    if (purchasedTiles.isEmpty) {
      return const PurchasedTileIndex._(<String, PurchasedTileAttribution>{});
    }
    final tileToProvince = _buildTileToProvinceMap(game);
    final membership = DiplomacyFactionMembership.from(game);
    final attributions = <String, PurchasedTileAttribution>{};
    for (final entry in purchasedTiles.entries) {
      final tileKey = entry.key;
      final owningGpId = entry.value;
      if (owningGpId.isEmpty) continue;
      final provinceId = tileToProvince[tileKey];
      if (provinceId == null) continue;
      final province = game.worldState.tryGetProvince(provinceId);
      if (province == null) continue;
      final sourceFactionId = province.ownerId;
      if (sourceFactionId == null || sourceFactionId.isEmpty) continue;
      if (!membership.isMinorOrTribe(sourceFactionId)) continue;
      attributions[tileKey] = PurchasedTileAttribution(
        tileKey: tileKey,
        owningGpId: owningGpId,
        sourceFactionId: sourceFactionId,
        provinceId: provinceId,
      );
    }
    return PurchasedTileIndex._(attributions);
  }

  final Map<String, PurchasedTileAttribution> _byTileKey;

  /// Returns the attribution for [tileKey], or `null` when the tile is
  /// not a purchased-land contract eligible for FRR.
  PurchasedTileAttribution? attributionForTileKey(String tileKey) =>
      _byTileKey[tileKey];

  /// Snapshot iterable over every retained attribution. Order is the
  /// iteration order of the underlying map; callers that need
  /// deterministic order MUST sort by [PurchasedTileAttribution.tileKey].
  Iterable<PurchasedTileAttribution> get attributions => _byTileKey.values;

  /// Number of attributions in the index (excluding filtered entries).
  int get length => _byTileKey.length;

  /// True when no purchased-tile attribution is eligible for FRR.
  bool get isEmpty => _byTileKey.isEmpty;

  /// True when at least one purchased-tile attribution is eligible for
  /// FRR.
  bool get isNotEmpty => _byTileKey.isNotEmpty;
}

/// Builds the inverse `tileKey → fullProvinceId` lookup from
/// `WorldState.tileKeysByRegionAndProvince`. Multiple provinces
/// claiming the same tile key are not expected; the first occurrence
/// wins, matching the contract of `tileKeysByRegionAndProvince` itself
/// (one province per tile key).
Map<String, String> _buildTileToProvinceMap(Game game) {
  final tileToProvince = <String, String>{};
  game.worldState.tileKeysByRegionAndProvince.forEach((regionId, byProvince) {
    byProvince.forEach((provinceId, tileKeys) {
      for (final tileKey in tileKeys) {
        tileToProvince.putIfAbsent(tileKey, () => provinceId);
      }
    });
  });
  return tileToProvince;
}
