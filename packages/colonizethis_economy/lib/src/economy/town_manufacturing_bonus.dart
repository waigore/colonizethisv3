import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'commodity_totals.dart';
import 'town_manufacturing_bonus_math.dart';
import 'town_manufacturing_delivered_raw.dart';

export 'town_manufacturing_bonus_math.dart';
export 'town_manufacturing_delivered_raw.dart';

/// Town manufacturing clustering bonus — game rollup, overlay preview, and
/// auto-offers bridge (Refs #3872; phase-7 split Refs #4049).
/// SPEC/game/extraction-and-improvements.md § Town manufacturing bonus.
///
/// Recipe eligibility / per-province math lives in
/// `town_manufacturing_bonus_math.dart`; the town-connected delivered-raw
/// province walk lives in `town_manufacturing_delivered_raw.dart`. Both are
/// re-exported here so callers keep one stable import surface.

/// Per-faction aggregated manufactured bonus keyed by faction id.
typedef FactionManufacturingBonus = Map<String, Map<CommodityId, int>>;

/// Per-province manufactured bonus keyed by full province id.
typedef ProvinceManufacturingBonus = Map<String, Map<CommodityId, int>>;

/// Preview per-province town manufacturing bonus for the province overlay and
/// order projections. SPEC/program/order-projections.md § Town manufacturing bonus preview.
///
/// Returns only provinces with a strictly positive bonus quantity. Empty when
/// [tileMapByRegion] is null or empty (same as zero extraction preview).
ProvinceManufacturingBonus previewTownManufacturingBonusByProvince({
  required Game game,
  required MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return const {};
  }
  final gpConnectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final nonGpConnectivity = resolveNonGreatPowerConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  return computeTownManufacturingBonusForGame(
    game: game,
    tileMapByRegion: tileMapByRegion,
    gpConnectivityByPlayerId: gpConnectivity,
    nonGpConnectivityByFactionId: nonGpConnectivity,
  ).bonusByProvinceId;
}

/// Computes per-province then per-faction town manufacturing bonus maps.
({
  ProvinceDeliveredRawExtraction deliveredRawByProvince,
  ProvinceManufacturingBonus bonusByProvinceId,
  FactionManufacturingBonus bonusByFactionId,
})
computeTownManufacturingBonusForGame({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> gpConnectivityByPlayerId,
  required Map<String, ConnectivityResult> nonGpConnectivityByFactionId,
}) {
  final townConnectedByProvinceId = resolveTownConnectedTileKeysByProvince(
    game: game,
    tileMapByRegion: tileMapByRegion,
  );
  final deliveredRawByProvince = computeTownConnectedDeliveredRawByProvince(
    game: game,
    tileMapByRegion: tileMapByRegion,
    gpConnectivityByPlayerId: gpConnectivityByPlayerId,
    nonGpConnectivityByFactionId: nonGpConnectivityByFactionId,
    townConnectedByProvinceId: townConnectedByProvinceId,
  );

  final bonusByProvince = <String, Map<CommodityId, int>>{};
  for (final province in allProvinces(game.worldState)) {
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    final raw = deliveredRawByProvince[province.id];
    if (raw == null || raw.isEmpty) continue;
    final bonus = computeTownManufacturingBonusForProvince(
      townDevelopmentLevel: province.townDevelopmentLevel,
      townConnectedDeliveredRawByCommodity: raw,
      techUnlocked: _techUnlockedForOwner(game, ownerId),
    );
    if (bonus.isNotEmpty) {
      bonusByProvince[province.id] = bonus;
    }
  }

  final bonusByFactionId = <String, Map<CommodityId, int>>{};
  for (final entry in bonusByProvince.entries) {
    final province = game.worldState.tryGetProvince(entry.key);
    final ownerId = province?.ownerId;
    if (ownerId == null) continue;
    final factionTotals = bonusByFactionId.putIfAbsent(ownerId, () => {});
    for (final c in entry.value.entries) {
      addUnits(factionTotals, c.key, c.value);
    }
  }

  if (bonusByFactionId.isNotEmpty) {
    economyLog.i(
      'logic: town_manufacturing_bonus factions=${bonusByFactionId.length} '
      'provinces=${bonusByProvince.length}',
    );
  }

  return (
    deliveredRawByProvince: deliveredRawByProvince,
    bonusByProvinceId: bonusByProvince,
    bonusByFactionId: bonusByFactionId,
  );
}

/// Converts non-GP town manufacturing bonus into priority-1 world-market offers.
Map<String, List<TradeOrder>> townManufacturingBonusToAutoOffers({
  required Game game,
  required FactionManufacturingBonus bonusByFactionId,
}) {
  if (bonusByFactionId.isEmpty) return const {};
  final out = <String, List<TradeOrder>>{};
  for (final entry in bonusByFactionId.entries) {
    final factionId = entry.key;
    if (game.playerById(factionId) != null) continue;
    final orders = <TradeOrder>[];
    final sortedCommodities = entry.value.keys.toList()..sort();
    for (final commodityId in sortedCommodities) {
      final qty = entry.value[commodityId] ?? 0;
      if (qty <= 0) continue;
      orders.add(
        TradeOrder(
          commodityId: commodityId,
          type: TradeOrderType.offer,
          quantity: qty,
          priority: 1,
        ),
      );
    }
    if (orders.isNotEmpty) out[factionId] = orders;
  }
  return out;
}

Map<String, bool>? _techUnlockedForOwner(Game game, String ownerId) {
  final player = game.playerById(ownerId);
  return player?.techUnlocked;
}
