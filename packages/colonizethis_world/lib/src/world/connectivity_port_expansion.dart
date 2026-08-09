/// Sea-path port wiring, blockade pruning, and town-rule connectivity closure.
/// Standalone library (wave 5 slice B, Refs #4125) complementing
/// [connectivity_road_propagation.dart].
library;

import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'connectivity_metrics.dart';
import 'connectivity_tile_helpers.dart';
import 'port_seaboard_registry_key.dart';
import 'topology_helpers.dart';
import '../world_constants.dart';

void tryEnqueueSeaConnectedPortExpansion({
  required String portKey,
  required Set<String> connected,
  required Set<String> owned,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, int> pathCap,
  required Queue<String> expansionSeedQueue,
}) {
  if (connected.contains(portKey)) return;
  final coords = parseTileKeyCoordinates(portKey);
  if (coords == null) return;
  final fullProvinceId = '${coords.regionId}|${coords.provinceLocalId}';
  if (!owned.contains(fullProvinceId)) return;
  if (tileMapByRegion[coords.regionId] == null) return;
  if (coords.x < 0 || coords.y < 0) return;

  connected.add(portKey);
  pathCap[portKey] = 4;
  expansionSeedQueue.add(portKey);
}

void removeBlockadedPortTilesExceptCapital({
  required Set<String> connected,
  required Map<String, int> pathCap,
  required Set<String> blockadedPortProvinces,
  required String capitalProvinceId,
}) {
  for (final key in connected.toList()) {
    final fullProvinceId = fullProvinceIdFromTileKey(key);
    if (fullProvinceId == null) continue;
    if (!blockadedPortProvinces.contains(fullProvinceId)) continue;
    if (fullProvinceId == capitalProvinceId) continue;
    connected.remove(key);
    pathCap.remove(key);
  }
}

Set<String> seaConnectedPortKeysForCapital({
  required CapitalTile capital,
  required WorldState worldState,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required Set<String> seaZoneNodeIds,
  required Set<String> ownedProvinceIds,
  required Set<String> blockadedPortProvinces,
  required Set<String> capitalRegionPortKeys,
  ConnectivityHotPathMetrics? metrics,
}) {
  final out = <String>{};
  final capitalProvinceBlockaded = blockadedPortProvinces.contains(
    capital.provinceId,
  );
  final capitalOnSeaboard = isCapitalTileOnSeaboard(
    capital,
    tileMapByRegion,
    provinceIdsByType,
  );
  if (capitalOnSeaboard && !capitalProvinceBlockaded) {
    final prefixedTopology = topologyUsesPrefixedIds(topology);
    final provinceIdForLookup = prefixedTopology
        ? capital.provinceId
        : (ProvinceId.isPrefixed(capital.provinceId)
              ? ProvinceId.localIdFrom(capital.provinceId)
              : capital.provinceId);
    final capitalSeaZones = seaZoneIdsAdjacentToProvince(
      topology,
      provinceIdForLookup,
      regionId: ProvinceId.isPrefixed(capital.provinceId)
          ? ProvinceId.regionIdFrom(capital.provinceId)
          : null,
    );
    final seaReachable = seaZonesReachableBySeaPath(
      topology,
      capitalSeaZones,
      onDequeue: metrics?.recordSeaZoneBfsDequeue,
    );
    for (final entry in worldState.portsByProvinceSeaboard.entries) {
      final portMeta = decodePortSeaboardRegistryKey(entry.key);
      if (portMeta == null) continue;
      if (blockadedPortProvinces.contains(portMeta.fullProvinceId)) continue;
      final seaZoneIdForReachable = prefixedTopology && portMeta.isPrefixedKey
          ? '${portMeta.regionId}|${portMeta.seaZoneId}'
          : portMeta.seaZoneId;
      if (!seaReachable.contains(seaZoneIdForReachable)) continue;
      if (!ownedProvinceIds.contains(portMeta.fullProvinceId)) continue;
      out.add(entry.value);
    }
    return out;
  }
  if (!capitalOnSeaboard) {
    for (final portKey in capitalRegionPortKeys) {
      final portProvinceId = fullProvinceIdFromTileKey(portKey);
      if (portProvinceId == null) {
        out.add(portKey);
        continue;
      }
      if (!blockadedPortProvinces.contains(portProvinceId)) {
        out.add(portKey);
      }
    }
  }
  return out;
}

/// § Connectivity (Game Rule) Town rule: 4-adjacent to a connected town in the **same** province.
///
/// [townByTileKey] is the player-scoped town-tile → province map prepared by
/// `_buildPerPlayerProvinceCaches` in a single dual-region scan (Refs #2394).
void applyTownRuleConnectivityClosure({
  required Map<String, Province> townByTileKey,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required WorldState worldState,
  required Map<String, (String, String)> portTileToProvinceSeaZone,
  required Set<String> connected,
  required Map<String, int> pathCap,
  ConnectivityHotPathMetrics? metrics,
}) {
  final pendingTowns = Queue<String>();
  final queuedTowns = <String>{};
  final expandedTowns = <String>{};

  void enqueueTownForExpansion(String tk) {
    if (!connected.contains(tk)) return;
    assert(
      !expandedTowns.contains(tk),
      'town-rule worklist must not re-enqueue an already-expanded town tile: $tk',
    );
    if (!queuedTowns.add(tk)) return;
    pendingTowns.add(tk);
  }

  for (final tk in townByTileKey.keys) {
    enqueueTownForExpansion(tk);
  }

  while (pendingTowns.isNotEmpty) {
    final tk = pendingTowns.removeFirst();
    metrics?.recordTownRuleWorklistDequeue();
    queuedTowns.remove(tk);
    expandedTowns.add(tk);

    final province = townByTileKey[tk];
    if (province == null) continue;

    final coords = parseTileKeyCoordinates(tk);
    if (coords == null) continue;
    if (coords.x < 0 || coords.y < 0) continue;
    final map = tileMapByRegion[coords.regionId];
    if (map == null) continue;

    for (final d in kGridNeighborsCardinal4) {
      final nx = coords.x + d.$1;
      final ny = coords.y + d.$2;
      if (nx < 0 || nx >= map.width || ny < 0 || ny >= map.height) continue;
      final cell = map.cell(nx, ny);
      if (!isLandProvinceGridCell(cell, coords.regionId, provinceIdsByType)) {
        continue;
      }
      if (cell != coords.provinceLocalId) continue;
      final nKey = CapitalTile.tileKey(coords.regionId, province.id, nx, ny);
      if (connected.contains(nKey)) continue;
      connected.add(nKey);
      pathCap[nKey] =
          pathCap[tk] ??
          transportLevelAtTile(worldState, tk, portTileToProvinceSeaZone);
      if (townByTileKey.containsKey(nKey)) {
        enqueueTownForExpansion(nKey);
      }
    }
  }
}
