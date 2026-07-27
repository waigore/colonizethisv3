import 'package:colonizethis_data/colonizethis_data.dart'
    show extractionCapForUnlocked;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        GamePlayerLookup,
        WorldStateProvinceLookup,
        collectPortTileKeys,
        computeTileExtractionDisplayContribution,
        kMineralResourceIds,
        resolveConnectivity;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../../../core/utils/prefixed_id.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_tile_capital_link_preview.dart';

/// Display-only preview from post-resolution connectivity and extraction rules.
///
/// Returns null when map data is missing, the tile is not human-owned land, or
/// the tile is a sea cell (province overlay passes [isLandTile] false for sea).
ProvinceTileCapitalLinkPreview? provinceTileCapitalLinkPreview({
  required ct_models.Game game,
  required String humanPlayerId,
  required String? selectedTileKey,
  required bool isLandTile,
  required GameMapData? mapData,
}) {
  if (selectedTileKey == null || !isLandTile) {
    return null;
  }
  final tileMapByRegion = mapData?.tileMapByRegion;
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return null;
  }
  final parsed = tryParseTileKey(selectedTileKey);
  if (parsed == null) {
    return null;
  }
  final provinceId = '${parsed.regionId}|${parsed.provinceLocalId}';
  final province = game.worldState.tryGetProvince(provinceId);
  if (province?.ownerId != humanPlayerId) {
    return null;
  }
  final player = game.playerById(humanPlayerId);
  if (player == null) {
    return null;
  }

  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: mapData!.combinedTopology,
  );
  final cr = connectivity[humanPlayerId];
  if (cr == null) {
    return null;
  }

  final connected = cr.connected.contains(selectedTileKey);
  final prospected =
      game.worldState.playerProspectedTiles[humanPlayerId] ?? const <String>{};
  final contribution = computeTileExtractionDisplayContribution(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: selectedTileKey,
    connectedTileKeys: cr.connected,
    pathTransportCap: cr.pathTransportCap,
    connectedByRoadRule: cr.connectedByRoadRule,
    portTileKeys: collectPortTileKeys(game),
    capitalProvinceId: player.capitalProvinceId,
    techCapForCommodity: (_) => extractionCapForUnlocked(player.techUnlocked),
    isCommodityExtractable: (tk, commodityId) =>
        !kMineralResourceIds.contains(commodityId) || prospected.contains(tk),
  );

  final full = contribution?.full ?? 0;
  final effective = contribution?.effective ?? 0;
  return ProvinceTileCapitalLinkPreview(
    isCapitalConnected: connected,
    pathTransportLevel:
        connected ? cr.pathTransportCap[selectedTileKey] : null,
    extractionEffective: full > 0 ? effective : null,
    extractionFull: full,
  );
}
