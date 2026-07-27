import 'package:colonizethis_data/colonizethis_data.dart'
    show extractionCapForResourceForUnlocked;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;

/// Display-only capital-link and per-tile extraction for MAP20001 Tile section.
///
/// Computed once per overlay host build from cached map data and connectivity;
/// the overlay widget must not recompute connectivity during its own build.
class ProvinceTileConnectivityDisplay {
  const ProvinceTileConnectivityDisplay({
    required this.capitalConnected,
    this.pathTransportLevel,
    this.extractionEffective,
    this.extractionFull,
  });

  final bool capitalConnected;

  /// Present when [capitalConnected] and the connectivity pass recorded a cap.
  final int? pathTransportLevel;

  final int? extractionEffective;
  final int? extractionFull;

  bool get showExtractionRow =>
      extractionEffective != null &&
      extractionFull != null &&
      extractionFull! > 0;
}

/// Resolves human connectivity once for overlay hosts (shared with tile preview).
ConnectivityResult? humanConnectivityPreview({
  required ct_models.Game game,
  required String humanPlayerId,
  required GameMapData? mapData,
}) {
  final tileMapByRegion = mapData?.tileMapByRegion;
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return null;
  }
  return resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: mapData!.combinedTopology,
  )[humanPlayerId];
}

/// Tile capital-link and E-of-F preview for the province overlay Tile section.
///
/// Returns null when rows must be omitted (sea-zone context, unrevealed tile,
/// foreign-owned province, sea tile, or missing map data). Refs #4149.
ProvinceTileConnectivityDisplay? provinceTileConnectivityDisplayPreview({
  required ct_models.Game game,
  required String humanPlayerId,
  required String provinceId,
  required String selectedTileKey,
  required GameMapData? mapData,
  required bool isSeaZoneContext,
  required bool tileIsSea,
  required bool tileRevealed,
  ConnectivityResult? connectivityForHuman,
}) {
  if (isSeaZoneContext || !tileRevealed || tileIsSea) {
    return null;
  }

  final province = game.worldState.tryGetProvince(provinceId);
  if (province?.ownerId != humanPlayerId) {
    return null;
  }

  final tileMapByRegion = mapData?.tileMapByRegion;
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return null;
  }

  final cr =
      connectivityForHuman ??
      humanConnectivityPreview(
        game: game,
        humanPlayerId: humanPlayerId,
        mapData: mapData,
      );
  if (cr == null) {
    return null;
  }

  final player = game.playerById(humanPlayerId);
  if (player == null) {
    return null;
  }

  final connected = cr.connected.contains(selectedTileKey);
  final pathLevel = connected ? cr.pathTransportCap[selectedTileKey] : null;
  final prospected =
      game.worldState.playerProspectedTiles[humanPlayerId] ?? const <String>{};
  final provincesByFullId = buildProvinceIndex(game);
  final portTileKeys = collectPortTileKeys(game);

  final contribution = computeTileExtractionDisplayContribution(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: selectedTileKey,
    connectedTileKeys: cr.connected,
    pathTransportCap: cr.pathTransportCap,
    connectedByRoadRule: cr.connectedByRoadRule,
    portTileKeys: portTileKeys,
    capitalProvinceId: player.capitalProvinceId,
    provincesByFullId: provincesByFullId,
    techCapForCommodity: (commodityId) =>
        extractionCapForResourceForUnlocked(player.techUnlocked, commodityId),
    isCommodityExtractable: (tileKey, commodityId) =>
        !kProspectRequiredResourceIds.contains(commodityId) ||
        prospected.contains(tileKey),
  );

  return ProvinceTileConnectivityDisplay(
    capitalConnected: connected,
    pathTransportLevel: pathLevel,
    extractionEffective: contribution != null && contribution.full > 0
        ? contribution.effective
        : null,
    extractionFull:
        contribution != null && contribution.full > 0 ? contribution.full : null,
  );
}
