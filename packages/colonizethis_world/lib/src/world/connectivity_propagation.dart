/// Capital-connectivity propagation orchestration (Road rule, sea-path port wiring,
/// blockade pruning, Town rule closure). Standalone library (extracted from the
/// former `connectivity_resolver.dart` `part` chain, Refs #3544 Step 3) so the
/// propagation algorithm can be understood, imported, and unit-tested without
/// pulling in the resolver. Public surface is [connectedTilesForPlayer]; road BFS
/// and port-expansion passes live in sibling libraries (Refs #4125 slice B).
library;

import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'connectivity_metrics.dart';
import 'connectivity_port_expansion.dart';
import 'connectivity_result.dart';
import 'connectivity_road_propagation.dart';
import 'connectivity_tile_helpers.dart';

/// Resolves the connected tile set + path transport cap for a single faction's
/// capital. SPEC/game/capital-and-connectivity. Shared by Great-Power and
/// non-Great-Power connectivity resolution.
ConnectivityResult connectedTilesForPlayer({
  required Game game,
  required String playerId,
  required CapitalTile capital,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  required Set<String> provinceIdsByType,
  required Set<String> seaZoneNodeIds,
  required Map<String, (String, String)> portInfo,
  required Set<String> owned,
  required Map<String, Province> townByTileKey,
  Set<String> blockadedPortProvinces = const {},
  ConnectivityHotPathMetrics? metrics,
}) {
  final worldState = game.worldState;
  final tileState = worldState.tileState;
  if (!owned.contains(capital.provinceId)) {
    return const ConnectivityResult(connected: {});
  }

  final capitalRegionId = capital.regionId;
  final mapOpt = tileMapByRegion[capitalRegionId];
  if (mapOpt == null) return const ConnectivityResult(connected: {});

  final capitalKey = capital.toTileKey();
  final connected = <String>{capitalKey};
  final pathCap = <String, int>{};
  pathCap[capitalKey] = transportLevelAtTile(worldState, capitalKey, portInfo);

  // Road rule: a tile may expand connectivity when it carries a road/rail or a
  // port. Shared by both propagation passes so the rule has a single source;
  // the second (port-expansion) pass intentionally omits the capital seed since
  // the capital tile is already connected after the first pass. SPEC/game/
  // capital-and-connectivity.md § Connectivity (Game Rule).
  bool expandsViaRoadOrPort(String tileKey) =>
      (tileState.roadLevel(tileKey) > 0) || portInfo.containsKey(tileKey);

  runConnectivityRoadPropagation(
    queue: Queue<String>()..add(capitalKey),
    connected: connected,
    pathCap: pathCap,
    worldState: worldState,
    portTileToProvinceSeaZone: portInfo,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    ownedProvinceIds: owned,
    canExpandFrom: (tileKey) =>
        (tileKey == capitalKey) || expandsViaRoadOrPort(tileKey),
    metrics: metrics,
  );

  // Port connection rule: (1) capital on seaboard → ports reachable via sea-path (BFS S–S); (2) else only ports reachable by road/rail from capital. SPEC/game/capital-and-connectivity § Port connection to capital, Sea paths.
  final capitalRegionPortKeys = <String>{
    for (final k in connected)
      if (portInfo[k] != null &&
          parseTileKeyCoordinates(k)?.regionId == capitalRegionId)
        k,
  };

  final seaConnectedPortKeys = seaConnectedPortKeysForCapital(
    capital: capital,
    worldState: worldState,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    seaZoneNodeIds: seaZoneNodeIds,
    ownedProvinceIds: owned,
    blockadedPortProvinces: blockadedPortProvinces,
    capitalRegionPortKeys: capitalRegionPortKeys,
    metrics: metrics,
  );
  // When capital province is blockaded, seaConnectedPortKeys stays empty (no sea connectivity). SPEC § Blockade.

  final expansionSeedQueue = Queue<String>();
  for (final portKey in seaConnectedPortKeys) {
    tryEnqueueSeaConnectedPortExpansion(
      portKey: portKey,
      connected: connected,
      owned: owned,
      tileMapByRegion: tileMapByRegion,
      pathCap: pathCap,
      expansionSeedQueue: expansionSeedQueue,
    );
  }

  runConnectivityRoadPropagation(
    queue: expansionSeedQueue,
    connected: connected,
    pathCap: pathCap,
    worldState: worldState,
    portTileToProvinceSeaZone: portInfo,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    ownedProvinceIds: owned,
    canExpandFrom: expandsViaRoadOrPort,
    metrics: metrics,
  );

  // SPEC § Blockade: no tiles in a blockaded port province contribute; remove any tile in such a province (except capital province: its tiles remain when it is blockaded, only sea connectivity is severed).
  if (blockadedPortProvinces.isNotEmpty) {
    removeBlockadedPortTilesExceptCapital(
      connected: connected,
      pathCap: pathCap,
      blockadedPortProvinces: blockadedPortProvinces,
      capitalProvinceId: capital.provinceId,
    );
  }

  final connectedByRoadRule = Set<String>.from(connected);
  applyTownRuleConnectivityClosure(
    townByTileKey: townByTileKey,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    worldState: worldState,
    portTileToProvinceSeaZone: portInfo,
    connected: connected,
    pathCap: pathCap,
    metrics: metrics,
  );

  return ConnectivityResult(
    connected: connected,
    pathTransportCap: pathCap,
    connectedByRoadRule: connectedByRoadRule,
  );
}
