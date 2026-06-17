part of 'connectivity_resolver.dart';

void _tryEnqueueSeaConnectedPortExpansion({
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

void _removeBlockadedPortTilesExceptCapital({
  required Set<String> connected,
  required Map<String, int> pathCap,
  required Set<String> blockadedPortProvinces,
  required String capitalProvinceId,
}) {
  for (final key in connected.toList()) {
    final fullProvinceId = _fullProvinceIdFromTileKey(key);
    if (fullProvinceId == null) continue;
    if (!blockadedPortProvinces.contains(fullProvinceId)) continue;
    if (fullProvinceId == capitalProvinceId) continue;
    connected.remove(key);
    pathCap.remove(key);
  }
}

ConnectivityResult _connectedTilesForPlayer({
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
  pathCap[capitalKey] = _transportLevelAtTile(worldState, capitalKey, portInfo);

  // Road rule: a tile may expand connectivity when it carries a road/rail or a
  // port. Shared by both propagation passes so the rule has a single source;
  // the second (port-expansion) pass intentionally omits the capital seed since
  // the capital tile is already connected after the first pass. SPEC/game/
  // capital-and-connectivity.md § Connectivity (Game Rule).
  bool expandsViaRoadOrPort(String tileKey) =>
      (tileState.roadLevel(tileKey) > 0) || portInfo.containsKey(tileKey);

  _runConnectivityPropagation(
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
  );

  // Port connection rule: (1) capital on seaboard → ports reachable via sea-path (BFS S–S); (2) else only ports reachable by road/rail from capital. SPEC/game/capital-and-connectivity § Port connection to capital, Sea paths.
  final capitalRegionPortKeys = <String>{
    for (final k in connected)
      if (portInfo[k] != null &&
          parseTileKeyCoordinates(k)?.regionId == capitalRegionId)
        k,
  };

  final seaConnectedPortKeys = _seaConnectedPortKeysForCapital(
    capital: capital,
    worldState: worldState,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    seaZoneNodeIds: seaZoneNodeIds,
    ownedProvinceIds: owned,
    blockadedPortProvinces: blockadedPortProvinces,
    capitalRegionPortKeys: capitalRegionPortKeys,
  );
  // When capital province is blockaded, seaConnectedPortKeys stays empty (no sea connectivity). SPEC § Blockade.

  final expansionSeedQueue = Queue<String>();
  for (final portKey in seaConnectedPortKeys) {
    _tryEnqueueSeaConnectedPortExpansion(
      portKey: portKey,
      connected: connected,
      owned: owned,
      tileMapByRegion: tileMapByRegion,
      pathCap: pathCap,
      expansionSeedQueue: expansionSeedQueue,
    );
  }

  _runConnectivityPropagation(
    queue: expansionSeedQueue,
    connected: connected,
    pathCap: pathCap,
    worldState: worldState,
    portTileToProvinceSeaZone: portInfo,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    ownedProvinceIds: owned,
    canExpandFrom: expandsViaRoadOrPort,
  );

  // SPEC § Blockade: no tiles in a blockaded port province contribute; remove any tile in such a province (except capital province: its tiles remain when it is blockaded, only sea connectivity is severed).
  if (blockadedPortProvinces.isNotEmpty) {
    _removeBlockadedPortTilesExceptCapital(
      connected: connected,
      pathCap: pathCap,
      blockadedPortProvinces: blockadedPortProvinces,
      capitalProvinceId: capital.provinceId,
    );
  }

  final connectedByRoadRule = Set<String>.from(connected);
  _applyTownRuleConnectivityClosure(
    townByTileKey: townByTileKey,
    tileMapByRegion: tileMapByRegion,
    provinceIdsByType: provinceIdsByType,
    worldState: worldState,
    portTileToProvinceSeaZone: portInfo,
    connected: connected,
    pathCap: pathCap,
  );

  return ConnectivityResult(
    connected: connected,
    pathTransportCap: pathCap,
    connectedByRoadRule: connectedByRoadRule,
  );
}

void _runConnectivityPropagation({
  required Queue<String> queue,
  required Set<String> connected,
  required Map<String, int> pathCap,
  required WorldState worldState,
  required Map<String, (String, String)> portTileToProvinceSeaZone,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required Set<String> ownedProvinceIds,
  required bool Function(String tileKey) canExpandFrom,
}) {
  propagateConnectivityBottleneckQueue(
    queue: queue,
    connected: connected,
    pathCap: pathCap,
    onDequeue: _recordConnectivityBottleneckDequeue,
    shouldExpandEdgesFrom: (key) {
      final coords = parseTileKeyCoordinates(key);
      if (coords == null) return false;
      final fullProvinceId = '${coords.regionId}|${coords.provinceLocalId}';
      if (coords.x < 0 || coords.y < 0) return false;
      if (!ownedProvinceIds.contains(fullProvinceId)) return false;
      final map = tileMapByRegion[coords.regionId];
      if (map == null) return false;
      return canExpandFrom(key);
    },
    neighborsOf: (key) {
      final coords = parseTileKeyCoordinates(key);
      if (coords == null) return const <String>[];
      if (coords.x < 0 || coords.y < 0) return const <String>[];
      final map = tileMapByRegion[coords.regionId];
      if (map == null) return const <String>[];
      return _adjacentTileKeys(
        coords.regionId,
        coords.provinceLocalId,
        coords.x,
        coords.y,
        map,
        provinceIdsByType,
      );
    },
    transportLevelAt: (neighbor) =>
        _transportLevelAtTile(worldState, neighbor, portTileToProvinceSeaZone),
  );
}

Set<String> _seaConnectedPortKeysForCapital({
  required CapitalTile capital,
  required WorldState worldState,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required Set<String> seaZoneNodeIds,
  required Set<String> ownedProvinceIds,
  required Set<String> blockadedPortProvinces,
  required Set<String> capitalRegionPortKeys,
}) {
  final out = <String>{};
  final capitalProvinceBlockaded = blockadedPortProvinces.contains(
    capital.provinceId,
  );
  final capitalOnSeaboard = _isCapitalTileOnSeaboard(
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
      onDequeue: _recordSeaZoneBfsDequeue,
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
      final portProvinceId = _fullProvinceIdFromTileKey(portKey);
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
/// [_buildPerPlayerProvinceCaches] in a single dual-region scan (Refs #2394).
void _applyTownRuleConnectivityClosure({
  required Map<String, Province> townByTileKey,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceIdsByType,
  required WorldState worldState,
  required Map<String, (String, String)> portTileToProvinceSeaZone,
  required Set<String> connected,
  required Map<String, int> pathCap,
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
    _recordTownRuleWorklistDequeue();
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
      if (!_isLandProvinceGridCell(cell, coords.regionId, provinceIdsByType)) {
        continue;
      }
      if (cell != coords.provinceLocalId) continue;
      final nKey = CapitalTile.tileKey(coords.regionId, province.id, nx, ny);
      if (connected.contains(nKey)) continue;
      connected.add(nKey);
      pathCap[nKey] =
          pathCap[tk] ??
          _transportLevelAtTile(worldState, tk, portTileToProvinceSeaZone);
      if (townByTileKey.containsKey(nKey)) {
        enqueueTownForExpansion(nKey);
      }
    }
  }
}
