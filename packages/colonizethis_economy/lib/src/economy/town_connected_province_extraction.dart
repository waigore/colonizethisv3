import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'commodity_totals.dart';
import 'non_gp_extraction_shared.dart';
import 'resource_extractor.dart';
import 'sea_transport.dart';
import 'town_connected_tile_walk.dart';

/// Shared mutable sinks + read-only inputs for town-connected province
/// extraction walks (Refs #3979). Package-internal — not re-exported from the
/// economy barrel.
final class TownConnectedProvinceExtractionContext {
  TownConnectedProvinceExtractionContext({
    required this.game,
    required this.tileMapByRegion,
    required this.provincesByFullId,
    required this.portTileKeys,
    required this.landByProvince,
    this.overseasByPlayerProvince,
  });

  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, Province> provincesByFullId;
  final Set<String> portTileKeys;
  final Map<String, Map<CommodityId, int>> landByProvince;

  /// GP overseas extraction staged by player → province → commodity.
  /// Null when the caller only accumulates land-side non-GP contributions.
  final Map<String, Map<String, Map<CommodityId, int>>>?
  overseasByPlayerProvince;
}

/// Accumulates GP town-connected tile extraction into [ctx.landByProvince]
/// (capital-relative land) and [ctx.overseasByPlayerProvince] (overseas).
void accumulateGpProvinceExtraction({
  required TownConnectedProvinceExtractionContext ctx,
  required Player player,
  required Province province,
  required Set<String> townConnected,
  required ConnectivityResult? connectivity,
}) {
  final overseasByPlayerProvince = ctx.overseasByPlayerProvince;
  if (overseasByPlayerProvince == null) return;

  final connected = connectivity?.connected ?? const <String>{};
  if (connected.isEmpty) return;
  final pathTransportCap = connectivity?.pathTransportCap ?? const {};
  final roadRuleTiles = connectivity?.connectedByRoadRule ?? const {};
  final prospected =
      ctx.game.worldState.playerProspectedTiles[player.id] ?? const {};
  final capitalRegionId = player.capitalTile?.regionId;

  forEachTownConnectedTileInProvince(
    connectedTiles: connected,
    townConnected: townConnected,
    provinceId: province.id,
    onTile: (tileKey) {
      final contribution = computeTileExtractionContributionForPlayer(
        game: ctx.game,
        tileMapByRegion: ctx.tileMapByRegion,
        player: player,
        tileKey: tileKey,
        connectedTileKeys: connected,
        pathTransportCap: pathTransportCap,
        connectedByRoadRule: roadRuleTiles,
        portTileKeys: ctx.portTileKeys,
        prospectedTileKeys: prospected,
        capitalRegionId: capitalRegionId,
        techCapForPlayer: (_) => extractionCapForUnlocked(player.techUnlocked),
        techCapForPlayerAndResource: (_, resourceId) =>
            extractionCapForResourceForUnlocked(
              player.techUnlocked,
              resourceId,
            ),
        provincesByFullId: ctx.provincesByFullId,
      );
      if (contribution == null || contribution.units <= 0) return;

      if (contribution.isLandRelativeToCapital) {
        final totals = ctx.landByProvince.putIfAbsent(province.id, () => {});
        addUnits(totals, contribution.commodityId, contribution.units);
      } else {
        final byProvince = overseasByPlayerProvince.putIfAbsent(
          player.id,
          () => {},
        );
        final totals = byProvince.putIfAbsent(province.id, () => {});
        addUnits(totals, contribution.commodityId, contribution.units);
      }
    },
  );
}

/// Accumulates non-GP town-connected tile extraction into [ctx.landByProvince].
void accumulateNonGpProvinceExtraction({
  required TownConnectedProvinceExtractionContext ctx,
  required Province province,
  required Set<String> townConnected,
  required ConnectivityResult connectivity,
  required String ownerId,
}) {
  forEachTownConnectedNonGpTileContributionInProvince(
    game: ctx.game,
    tileMapByRegion: ctx.tileMapByRegion,
    ownerId: ownerId,
    province: province,
    townConnected: townConnected,
    connectivity: connectivity,
    provincesByFullId: ctx.provincesByFullId,
    portTileKeys: ctx.portTileKeys,
    onContribution: (contribution) {
      final totals = ctx.landByProvince.putIfAbsent(province.id, () => {});
      addUnits(totals, contribution.commodityId, contribution.units);
    },
  );
}

/// Applies cargo-hold-capped overseas delivery into [landByProvince], preserving
/// sorted province-id allocation order (Refs #3979).
void applyOverseasCargoDeliveryToProvinces({
  required Game game,
  required Map<String, Map<String, Map<CommodityId, int>>>
  overseasByPlayerProvince,
  required Map<String, Map<CommodityId, int>> landByProvince,
}) {
  if (overseasByPlayerProvince.isEmpty) return;
  final fleetsById = fleetsByIdForWorld(game.worldState);
  for (final entry in overseasByPlayerProvince.entries) {
    final playerId = entry.key;
    final byProvince = entry.value;
    if (byProvince.isEmpty) continue;

    final overseasTotals = <CommodityId, int>{};
    for (final provinceTotals in byProvince.values) {
      for (final c in provinceTotals.entries) {
        addUnits(overseasTotals, c.key, c.value);
      }
    }
    final cargoHolds = cargoHoldsForHomeFleet(
      game,
      playerId,
      fleetsById: fleetsById,
    );
    final delivered = allocateOverseasToStockpile(
      overseasTotals,
      cargoHolds: cargoHolds,
    );

    final sortedProvinceIds = byProvince.keys.toList()..sort();
    for (final commodityId in delivered.keys) {
      var remaining = delivered[commodityId] ?? 0;
      if (remaining <= 0) continue;
      for (final provinceId in sortedProvinceIds) {
        if (remaining <= 0) break;
        final available = byProvince[provinceId]?[commodityId] ?? 0;
        if (available <= 0) continue;
        final take = available < remaining ? available : remaining;
        final totals = landByProvince.putIfAbsent(provinceId, () => {});
        addUnits(totals, commodityId, take);
        remaining -= take;
      }
    }
  }
}
