/// Tile-level capital-link and extraction preview for MAP20001 (Refs #4149).
///
/// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md (Tile section).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TileMapResult, extractionCapForUnlocked;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'economy_resource_constants.dart';
import 'game_lookup_helpers.dart';
import 'province_extraction_snapshot_builder.dart';

/// Cached display data for the Tile section capital-link and E-of-F rows.
class ProvinceTileCapitalLinkPreview {
  const ProvinceTileCapitalLinkPreview({
    required this.isCapitalConnected,
    this.pathTransportLevel,
    this.extractionEffective,
    required this.extractionFull,
  });

  final bool isCapitalConnected;
  final int? pathTransportLevel;
  final int? extractionEffective;
  final int extractionFull;

  bool get showExtraction => extractionFull > 0;
}

/// Display-only preview from post-resolution connectivity and extraction rules.
///
/// Returns null when map data is missing, the tile is not human-owned land, or
/// the tile is a sea cell ([isLandTile] false).
ProvinceTileCapitalLinkPreview? provinceTileCapitalLinkPreview({
  required Game game,
  required String humanPlayerId,
  required String? selectedTileKey,
  required bool isLandTile,
  required Map<String, TileMapResult>? tileMapByRegion,
  required MapTopology? topology,
}) {
  if (selectedTileKey == null || !isLandTile) {
    return null;
  }
  if (tileMapByRegion == null ||
      tileMapByRegion.isEmpty ||
      topology == null) {
    return null;
  }
  final parsed = parseTileKeyCoordinates(selectedTileKey);
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
    topology: topology,
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
