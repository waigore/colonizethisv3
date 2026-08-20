import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_lookup_helpers.dart';
import 'non_gp_tile_contribution.dart';
import 'town_connected_tile_walk.dart';

/// Tile keys for a non-GP pass. Extraction preserves
/// [ConnectivityResult.connected] insertion order; auto-offers sort ascending
/// for deterministic offer lists.
Iterable<String> nonGpTileKeysInPassOrder(
  Set<String> connected, {
  required bool sorted,
}) {
  if (sorted) {
    return connected.toList()..sort();
  }
  return connected;
}

/// Walks connected tiles for one non-GP faction and invokes [onContribution]
/// for each tile that yields units. Shared by extraction (aggregate totals)
/// and auto-offers (per-tile orders); [sortTileKeys] selects the pass ordering.
void forEachNonGpTileContribution({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String capitalProvinceId,
  required String capitalRegionId,
  required ConnectivityResult connectivity,
  required Set<String> portTileKeys,
  required Map<String, Province> provincesByFullId,
  required bool sortTileKeys,
  required void Function(String tileKey, NonGpTileContribution contribution)
  onContribution,
}) {
  final tileKeys = nonGpTileKeysInPassOrder(
    connectivity.connected,
    sorted: sortTileKeys,
  );
  for (final tileKey in tileKeys) {
    final contribution = computeNonGpTileContribution(
      game: game,
      tileMapByRegion: tileMapByRegion,
      factionCapitalProvinceId: capitalProvinceId,
      factionCapitalRegionId: capitalRegionId,
      tileKey: tileKey,
      connectedTileKeys: connectivity.connected,
      pathTransportCap: connectivity.pathTransportCap,
      connectedByRoadRule: connectivity.connectedByRoadRule,
      portTileKeys: portTileKeys,
      provincesByFullId: provincesByFullId,
    );
    if (contribution != null) {
      onContribution(tileKey, contribution);
    }
  }
}

/// Walks town-connected tiles in [provinceId] for a non-GP faction and invokes
/// [onContribution] for each tile that yields units. Shared by town manufacturing
/// bonus extraction and non-GP extraction/auto-offers paths (Refs #3939).
void forEachTownConnectedNonGpTileContributionInProvince({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String ownerId,
  required Province province,
  required Set<String> townConnected,
  required ConnectivityResult connectivity,
  required Map<String, Province> provincesByFullId,
  required Set<String> portTileKeys,
  required void Function(NonGpTileContribution contribution) onContribution,
}) {
  final capitalProvinceId = capitalProvinceIdForFaction(game, ownerId);
  final capitalRegionId = capitalRegionIdForFaction(game, ownerId);
  if (capitalProvinceId == null || capitalRegionId == null) return;

  forEachTownConnectedTileInProvince(
    connectedTiles: connectivity.connected,
    townConnected: townConnected,
    provinceId: province.id,
    onTile: (tileKey) {
      final contribution = computeNonGpTileContribution(
        game: game,
        tileMapByRegion: tileMapByRegion,
        factionCapitalProvinceId: capitalProvinceId,
        factionCapitalRegionId: capitalRegionId,
        tileKey: tileKey,
        connectedTileKeys: connectivity.connected,
        pathTransportCap: connectivity.pathTransportCap,
        connectedByRoadRule: connectivity.connectedByRoadRule,
        portTileKeys: portTileKeys,
        provincesByFullId: provincesByFullId,
      );
      if (contribution != null && contribution.units > 0) {
        onContribution(contribution);
      }
    },
  );
}
