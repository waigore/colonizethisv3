import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'commodity_totals.dart';
import 'game_lookup_helpers.dart';
import 'town_connected_province_extraction.dart';

/// Town manufacturing clustering bonus (Refs #3872).
/// SPEC/game/extraction-and-improvements.md § Town manufacturing bonus.

const int kTownManufacturingBonusDivisor = 4;

/// Multiplier for qualifying [townDevelopmentLevel] values (2 → 1, 4 → 2).
int townManufacturingBonusMultiplier(int townDevelopmentLevel) {
  return switch (townDevelopmentLevel) {
    2 => 1,
    4 => 2,
    _ => 0,
  };
}

bool isTownManufacturingRecipeEligible(ProductionRecipe recipe) {
  for (final inputId in recipe.inputQuantities.keys) {
    final commodity = CommodityCatalog.byId[inputId];
    if (commodity == null ||
        commodity.category != CommodityCategory.rawMaterial) {
      return false;
    }
  }
  return true;
}

/// Per-province manufactured bonus quantities from town-connected delivered
/// raw extraction.
Map<CommodityId, int> computeTownManufacturingBonusForProvince({
  required int townDevelopmentLevel,
  required Map<CommodityId, int> townConnectedDeliveredRawByCommodity,
  required Map<String, bool>? techUnlocked,
}) {
  final multiplier = townManufacturingBonusMultiplier(townDevelopmentLevel);
  if (multiplier <= 0 || townConnectedDeliveredRawByCommodity.isEmpty) {
    return const {};
  }
  final bonus = <CommodityId, int>{};
  for (final recipe in ProductionRecipesCatalog.all) {
    if (!isTownManufacturingRecipeEligible(recipe)) continue;
    if (!ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      techUnlocked,
    )) {
      continue;
    }
    var limiting = -1;
    for (final entry in recipe.inputQuantities.entries) {
      final rawQty = townConnectedDeliveredRawByCommodity[entry.key] ?? 0;
      limiting = limiting < 0
          ? rawQty
          : (rawQty < limiting ? rawQty : limiting);
    }
    if (limiting <= 0) continue;
    final outputQty =
        (limiting ~/ kTownManufacturingBonusDivisor) *
        multiplier *
        recipe.outputQuantity;
    if (outputQty <= 0) continue;
    addUnits(bonus, recipe.outputCommodityId, outputQty);
  }
  return bonus;
}

/// Per-province town-connected **delivered** raw extraction keyed by province id.
typedef ProvinceDeliveredRawExtraction = Map<String, Map<CommodityId, int>>;

/// Per-faction aggregated manufactured bonus keyed by faction id.
typedef FactionManufacturingBonus = Map<String, Map<CommodityId, int>>;

ProvinceDeliveredRawExtraction computeTownConnectedDeliveredRawByProvince({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> gpConnectivityByPlayerId,
  required Map<String, ConnectivityResult> nonGpConnectivityByFactionId,
  required Map<String, Set<String>> townConnectedByProvinceId,
}) {
  final provincesByFullId = buildProvinceIndex(game);
  final portTileKeys = collectPortTileKeys(game);
  final landByProvince = <String, Map<CommodityId, int>>{};
  final overseasByPlayerProvince =
      <String, Map<String, Map<CommodityId, int>>>{};
  final ctx = TownConnectedProvinceExtractionContext(
    game: game,
    tileMapByRegion: tileMapByRegion,
    provincesByFullId: provincesByFullId,
    portTileKeys: portTileKeys,
    landByProvince: landByProvince,
    overseasByPlayerProvince: overseasByPlayerProvince,
  );

  for (final province in allProvinces(game.worldState)) {
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    final townConnected = townConnectedByProvinceId[province.id];
    if (townConnected == null || townConnected.isEmpty) continue;

    final player = game.playerById(ownerId);
    if (player != null) {
      accumulateGpProvinceExtraction(
        ctx: ctx,
        player: player,
        province: province,
        townConnected: townConnected,
        connectivity: gpConnectivityByPlayerId[player.id],
      );
      continue;
    }

    final connectivity = nonGpConnectivityByFactionId[ownerId];
    if (connectivity == null) continue;
    accumulateNonGpProvinceExtraction(
      ctx: ctx,
      province: province,
      townConnected: townConnected,
      connectivity: connectivity,
      ownerId: ownerId,
    );
  }

  applyOverseasCargoDeliveryToProvinces(
    game: game,
    overseasByPlayerProvince: overseasByPlayerProvince,
    landByProvince: landByProvince,
  );

  return landByProvince;
}

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
