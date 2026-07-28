/// Empire Development panel read model. Refs #4175.
///
/// SPEC: SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show
        CommodityId,
        Game,
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        Orders,
        Unit,
        UnitStatus;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'commodity_totals.dart';
import 'economy_resource_constants.dart';
import 'game_lookup_helpers.dart';
import 'province_improvable_resource_counts.dart';
import 'resource_extractor.dart';
import 'tile_extraction_pipeline.dart';

/// One improvable commodity row within a province or purchased-land scope.
class DevelopmentImprovableCommodityRow {
  const DevelopmentImprovableCommodityRow({
    required this.commodityId,
    required this.tileKeys,
  });

  final String commodityId;
  final List<String> tileKeys;

  int get count => tileKeys.length;
}

/// Owned province or purchased-land grouping under a source province.
class DevelopmentPanelScopeRow {
  const DevelopmentPanelScopeRow({
    required this.scopeKey,
    required this.provinceId,
    required this.displayName,
    this.provinceOwnerId,
    this.provinceOwnerDisplayName,
    this.isPurchasedLand = false,
    this.improvableCommodities = const [],
  });

  /// Stable list key (province id for owned rows; `purchased:<provinceId>`).
  final String scopeKey;
  final String provinceId;
  final String displayName;
  final String? provinceOwnerId;
  final String? provinceOwnerDisplayName;
  final bool isPurchasedLand;
  final List<DevelopmentImprovableCommodityRow> improvableCommodities;

  bool get hasImprovableResources => improvableCommodities.isNotEmpty;
}

/// Per-region Development panel projection.
class DevelopmentPanelRegionModel {
  const DevelopmentPanelRegionModel({
    required this.regionId,
    required this.ownedScopes,
    required this.purchasedScopes,
    required this.landExtractionByCommodity,
    required this.idleBuilderCount,
    required this.idleEngineerCount,
  });

  final String regionId;
  final List<DevelopmentPanelScopeRow> ownedScopes;
  final List<DevelopmentPanelScopeRow> purchasedScopes;
  final Map<String, int> landExtractionByCommodity;
  final int idleBuilderCount;
  final int idleEngineerCount;
}

/// Full Development panel read model (both regions).
class DevelopmentPanelModel {
  const DevelopmentPanelModel({
    required this.oldWorld,
    required this.newWorld,
  });

  final DevelopmentPanelRegionModel oldWorld;
  final DevelopmentPanelRegionModel newWorld;

  DevelopmentPanelRegionModel forRegion(String regionId) =>
      regionId == kRegionNewWorld ? newWorld : oldWorld;
}

/// Builds the empire Development panel read model from post-resolution state.
DevelopmentPanelModel buildDevelopmentPanelModel({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, String> provinceDisplayNamesById,
  required Map<String, String> playerDisplayNamesById,
}) {
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final pendingUnitIds = _pendingWorkUnitIds(currentOrders, playerId);
  final idleCounts = _countIdleCivilians(
    game: game,
    playerId: playerId,
    pendingUnitIds: pendingUnitIds,
  );

  final ownerCache = ProvinceOwnerCache.of(game.worldState);

  return DevelopmentPanelModel(
    oldWorld: _buildRegionModel(
      game: game,
      playerId: playerId,
      regionId: kRegionOldWorld,
      tileMapByRegion: tileMapByRegion,
      landExtractionByCommodity: _extractionProjectionForRegion(
        game: game,
        playerId: playerId,
        regionId: kRegionOldWorld,
        tileMapByRegion: tileMapByRegion,
        connectivity: connectivity[playerId],
      ),
      idleBuilderCount: idleCounts.builders,
      idleEngineerCount: idleCounts.engineers,
      provinceDisplayNamesById: provinceDisplayNamesById,
      playerDisplayNamesById: playerDisplayNamesById,
      ownerCache: ownerCache,
    ),
    newWorld: _buildRegionModel(
      game: game,
      playerId: playerId,
      regionId: kRegionNewWorld,
      tileMapByRegion: tileMapByRegion,
      landExtractionByCommodity: _extractionProjectionForRegion(
        game: game,
        playerId: playerId,
        regionId: kRegionNewWorld,
        tileMapByRegion: tileMapByRegion,
        connectivity: connectivity[playerId],
      ),
      idleBuilderCount: idleCounts.builders,
      idleEngineerCount: idleCounts.engineers,
      provinceDisplayNamesById: provinceDisplayNamesById,
      playerDisplayNamesById: playerDisplayNamesById,
      ownerCache: ownerCache,
    ),
  );
}

DevelopmentPanelRegionModel _buildRegionModel({
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, int> landExtractionByCommodity,
  required int idleBuilderCount,
  required int idleEngineerCount,
  required Map<String, String> provinceDisplayNamesById,
  required Map<String, String> playerDisplayNamesById,
  required ProvinceOwnerCache ownerCache,
}) {
  final ownedProvinces =
      ownerCache.provincesOwnedByInRegion(playerId, regionId);
  final ownedScopes = <DevelopmentPanelScopeRow>[];
  for (final province in ownedProvinces) {
    final improvable = _improvableRowsFromCounts(
      provinceImprovableResourceTileCounts(
        game: game,
        provinceId: province.id,
        ownerId: playerId,
        tileMapByRegion: tileMapByRegion,
      ),
    );
    ownedScopes.add(
      DevelopmentPanelScopeRow(
        scopeKey: province.id,
        provinceId: province.id,
        displayName:
            provinceDisplayNamesById[province.id] ?? province.id,
        improvableCommodities: improvable,
      ),
    );
  }

  final purchasedScopes = _buildPurchasedScopes(
    game: game,
    playerId: playerId,
    regionId: regionId,
    tileMapByRegion: tileMapByRegion,
    provinceDisplayNamesById: provinceDisplayNamesById,
    playerDisplayNamesById: playerDisplayNamesById,
    ownerCache: ownerCache,
  );

  return DevelopmentPanelRegionModel(
    regionId: regionId,
    ownedScopes: ownedScopes,
    purchasedScopes: purchasedScopes,
    landExtractionByCommodity: landExtractionByCommodity,
    idleBuilderCount: idleBuilderCount,
    idleEngineerCount: idleEngineerCount,
  );
}

List<DevelopmentPanelScopeRow> _buildPurchasedScopes({
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, String> provinceDisplayNamesById,
  required Map<String, String> playerDisplayNamesById,
  required ProvinceOwnerCache ownerCache,
}) {
  final bySourceProvince = <String, List<String>>{};
  for (final entry in game.worldState.purchasedTilesByTileKey.entries) {
    if (entry.value != playerId) continue;
    final tileKey = entry.key;
    final provinceId = _provinceIdFromTileKey(tileKey);
    if (provinceId == null) continue;
    if (!provinceId.startsWith('$regionId|')) continue;
    bySourceProvince.putIfAbsent(provinceId, () => []).add(tileKey);
  }

  final scopes = <DevelopmentPanelScopeRow>[];
  final sortedProvinceIds = bySourceProvince.keys.toList()..sort();
  for (final provinceId in sortedProvinceIds) {
    final tileKeys = bySourceProvince[provinceId]!..sort();
    final improvable = _improvableRowsForTileKeys(
      game: game,
      playerId: playerId,
      tileKeys: tileKeys,
      tileMapByRegion: tileMapByRegion,
    );
    final ownerId = ownerCache.ownerOf(provinceId);
    scopes.add(
      DevelopmentPanelScopeRow(
        scopeKey: 'purchased:$provinceId',
        provinceId: provinceId,
        displayName:
            provinceDisplayNamesById[provinceId] ?? provinceId,
        provinceOwnerId: ownerId,
        provinceOwnerDisplayName: ownerId == null
            ? null
            : playerDisplayNamesById[ownerId] ?? ownerId,
        isPurchasedLand: true,
        improvableCommodities: improvable,
      ),
    );
  }
  return scopes;
}

List<DevelopmentImprovableCommodityRow> _improvableRowsFromCounts(
  Map<String, ProvinceImprovableCommodityCount> counts,
) {
  final rows = <DevelopmentImprovableCommodityRow>[];
  for (final commodity in CommodityCatalog.all) {
    final entry = counts[commodity.id];
    if (entry == null || entry.count <= 0) continue;
    rows.add(
      DevelopmentImprovableCommodityRow(
        commodityId: commodity.id,
        tileKeys: List<String>.from(entry.tileKeys),
      ),
    );
  }
  return rows;
}

List<DevelopmentImprovableCommodityRow> _improvableRowsForTileKeys({
  required Game game,
  required String playerId,
  required List<String> tileKeys,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final techUnlocked =
      game.playerById(playerId)?.techUnlocked ?? const <String, bool>{};
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  final tileState = game.worldState.tileState;
  final acc = <String, List<String>>{};

  for (final tileKey in tileKeys) {
    final resourceContext = resolveTileKeyResourceContext(
      tileKey: tileKey,
      tileMapByRegion: tileMapByRegion,
    );
    if (resourceContext == null) continue;

    final commodityId = resourceContext.commodityId;
    if (kMineralResourceIds.contains(commodityId) &&
        !prospected.contains(tileKey)) {
      continue;
    }

    final terrain = tileMapByRegion[resourceContext.regionId]?.terrainAt(
      resourceContext.x,
      resourceContext.y,
    );
    final cap = terrain == null
        ? extractionCapForResourceForUnlocked(techUnlocked, commodityId)
        : extractionCapForResourceOnTerrain(techUnlocked, commodityId, terrain);
    final improvement = tileState.improvementLevel(tileKey);
    if (improvement >= cap) continue;

    acc.putIfAbsent(commodityId, () => []).add(tileKey);
  }

  final rows = <DevelopmentImprovableCommodityRow>[];
  for (final commodity in CommodityCatalog.all) {
    final keys = acc[commodity.id];
    if (keys == null || keys.isEmpty) continue;
    keys.sort();
    rows.add(
      DevelopmentImprovableCommodityRow(
        commodityId: commodity.id,
        tileKeys: List<String>.from(keys),
      ),
    );
  }
  return rows;
}

Map<String, int> _extractionProjectionForRegion({
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
  required ConnectivityResult? connectivity,
}) {
  final player = game.playerById(playerId);
  if (player == null || connectivity == null) return const {};

  final connected = connectivity.connected;
  final pathTransportCap = connectivity.pathTransportCap;
  final roadRuleTiles = connectivity.connectedByRoadRule;
  final portTileKeys = collectPortTileKeys(game);
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  final provincesByFullId = buildProvinceIndex(game);
  final totals = <CommodityId, int>{};

  for (final tileKey in connected) {
    if (!tileKey.startsWith('$regionId|')) continue;
    final contribution = computeTileExtractionContributionForPlayer(
      game: game,
      tileMapByRegion: tileMapByRegion,
      player: player,
      tileKey: tileKey,
      connectedTileKeys: connected,
      pathTransportCap: pathTransportCap,
      connectedByRoadRule: roadRuleTiles,
      portTileKeys: portTileKeys,
      prospectedTileKeys: prospected,
      capitalRegionId: player.capitalTile?.regionId,
      provincesByFullId: provincesByFullId,
    );
    if (contribution == null || contribution.units <= 0) continue;
    addUnits(totals, contribution.commodityId, contribution.units);
  }

  final capBonus = game.capitalTileGrainBonusPerTurn;
  final capitalRegionId = player.capitalTile?.regionId;
  if (regionId == capitalRegionId &&
      player.capitalTile != null &&
      capBonus > 0) {
    addUnits(totals, CommodityCatalog.grain.id, capBonus);
  }

  final out = <String, int>{};
  for (final commodity in CommodityCatalog.all) {
    final qty = totals[commodity.id];
    if (qty == null || qty <= 0) continue;
    out[commodity.id] = qty;
  }
  return out;
}

String? _provinceIdFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return null;
  return '${parts[0]}|${parts[1]}';
}

Set<String> _pendingWorkUnitIds(Orders orders, String playerId) {
  final pending = orders.workOrdersByPlayerId[playerId] ?? const [];
  return pending.map((o) => o.unitId).toSet();
}

({int builders, int engineers}) _countIdleCivilians({
  required Game game,
  required String playerId,
  required Set<String> pendingUnitIds,
}) {
  var builders = 0;
  var engineers = 0;
  for (final unit in [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ]) {
    if (unit.ownerId != playerId) continue;
    if (unit.status != UnitStatus.idle) continue;
    if (unit.currentWork != null) continue;
    if (pendingUnitIds.contains(unit.id)) continue;
    if (unit.type == kUnitTypeBuilder) {
      builders++;
    } else if (unit.type == kUnitTypeEngineer) {
      engineers++;
    }
  }
  return (builders: builders, engineers: engineers);
}
