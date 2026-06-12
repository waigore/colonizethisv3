part of 'game_setup_helpers.dart';

void _spawnCivilianUnitsOfType({
  required Map<String, List<Unit>> unitsByRegion,
  required String ownerId,
  required String capitalProvinceId,
  required String capitalTileKey,
  required String capitalRegionId,
  required String unitType,
  required int count,
}) {
  final destination = unitsByRegion[capitalRegionId];
  if (destination == null) {
    throw StateError(
      'Unknown capital region "$capitalRegionId" for owner=$ownerId; '
      'expected one of $kRegionOldWorld / $kRegionNewWorld.',
    );
  }
  for (var k = 1; k <= count; k++) {
    destination.add(
      Unit(
        id: '${ownerId}_${unitType.toLowerCase()}_$k',
        type: unitType,
        ownerId: ownerId,
        locationProvinceId: capitalProvinceId,
        status: UnitStatus.idle,
        tileKey: capitalTileKey,
      ),
    );
  }
}

/// Adds starting civilian units for each civilian-owning faction at its capital tile.
Game addStartingUnits({required Game game, required GameSetupConfig config}) {
  final unitsByRegion = game.worldState.mutableUnitListsByRegion();

  Iterable<
    ({
      String id,
      String? capitalProvinceId,
      CapitalTile? capitalTile,
      bool requireCapitalTile,
    })
  >
  civilianOwners() sync* {
    for (final player in game.players) {
      yield (
        id: player.id,
        capitalProvinceId: player.capitalProvinceId,
        capitalTile: player.capitalTile,
        requireCapitalTile: true,
      );
    }
    for (final minor in game.minorNations) {
      yield (
        id: minor.id,
        capitalProvinceId: minor.capitalProvinceId,
        capitalTile: minor.capitalTile,
        requireCapitalTile: false,
      );
    }
    for (final tribe in game.tribes) {
      yield (
        id: tribe.id,
        capitalProvinceId: tribe.capitalProvinceId,
        capitalTile: tribe.capitalTile,
        requireCapitalTile: false,
      );
    }
  }

  for (final owner in civilianOwners()) {
    final ownerId = owner.id;
    final capitalProvinceId = owner.capitalProvinceId;
    final capitalTile = owner.capitalTile;
    if (capitalProvinceId == null || capitalTile == null) {
      if (!owner.requireCapitalTile) continue;
      throw StateError(
        'Cannot spawn starting civilians without capital tile: owner=$ownerId',
      );
    }
    final capitalTileKey = capitalTile.toTileKey();
    final tileProvinceId = Unit.provinceIdFromTileKey(capitalTileKey);
    if (tileProvinceId == null || tileProvinceId != capitalProvinceId) {
      throw StateError(
        'Capital tile/province mismatch for starting civilians: '
        'owner=$ownerId capitalProvinceId=$capitalProvinceId '
        'capitalTileKey=$capitalTileKey',
      );
    }
    final capitalRegionId = ProvinceId.regionIdFrom(capitalProvinceId);

    final unitConfig = config.startingResources.startingCivilianUnits;
    for (final entry in unitConfig.entries) {
      _spawnCivilianUnitsOfType(
        unitsByRegion: unitsByRegion,
        ownerId: ownerId,
        capitalProvinceId: capitalProvinceId,
        capitalTileKey: capitalTileKey,
        capitalRegionId: capitalRegionId,
        unitType: entry.key,
        count: entry.value,
      );
    }
  }

  return game.copyWith(
    worldState: game.worldState.mapBothRegionUnits(
      (rid, _) => unitsByRegion[rid]!,
    ),
  );
}

void _addStartingRegimentsForPlayer({
  required Player player,
  required String capitalProvinceId,
  required String regionId,
  required int regimentCount,
  required Map<String, List<Unit>> unitsByRegion,
}) {
  if (regimentCount <= 0) return;
  final destination = unitsByRegion[regionId];
  if (destination == null) {
    throw StateError(
      'Unknown capital region "$regionId" for player=${player.id}; '
      'expected one of $kRegionOldWorld / $kRegionNewWorld.',
    );
  }
  final regimentTypeId = startingRegimentTypeForPlayer(player);
  for (var i = 0; i < regimentCount; i++) {
    destination.add(
      Unit(
        id: '${player.id}_${regimentTypeId}_reg${i + 1}',
        type: regimentTypeId,
        ownerId: player.id,
        locationProvinceId: capitalProvinceId,
        status: UnitStatus.idle,
      ),
    );
  }
}

int _mergeHomeFleetShipsForPlayer({
  required Player player,
  required String regionId,
  required String localProvinceId,
  required int shipCount,
  required List<Fleet> fleets,
  required Map<String, int> fleetIndexById,
  required int nextSeq,
}) {
  if (shipCount <= 0 || regionId != kRegionOldWorld) return nextSeq;
  final fullProvinceId = '$regionId|$localProvinceId';
  final homeFleetId = homeFleetIdFor(player.id);
  final existingIndex = fleetIndexById[homeFleetId];
  final existingFleet =
      existingIndex != null ? fleets[existingIndex] : null;
  final existingShips = existingFleet?.ships ?? const <ShipInstance>[];
  final shipTypeId = startingShipTypeForPlayer(player);
  final (seqAfter, newInstances) = mintShipInstances(
    nextShipInstanceSeq: nextSeq,
    typeIds: [for (var i = 0; i < shipCount; i++) shipTypeId],
  );

  final homeFleet = Fleet(
    id: homeFleetId,
    ownerId: player.id,
    seaZoneId: null,
    inPortAtProvinceId: fullProvinceId,
    regionId: regionId,
    ships: [...existingShips, ...newInstances],
  );
  if (existingFleet == null) {
    fleets.add(homeFleet);
    fleetIndexById[homeFleetId] = fleets.length - 1;
  } else {
    fleets[existingIndex!] = homeFleet;
  }
  return seqAfter;
}

/// Adds starting land regiments and home-fleet ships for each Great Power.
Game addStartingMilitaryAndNaval({
  required Game game,
  required GameSetupConfig config,
  required MapTopology topologyOldWorld,
}) {
  final starting = config.startingResources;
  final regimentCount = starting.initialMilitaryRegiments;
  final shipCount = starting.initialNavalShips;

  if (regimentCount <= 0 && shipCount <= 0) return game;

  final unitsByRegion = game.worldState.mutableUnitListsByRegion();
  var fleets = List<Fleet>.from(game.worldState.fleets);
  final fleetIndexById = <String, int>{
    for (var i = 0; i < fleets.length; i++) fleets[i].id: i,
  };
  var nextSeq = game.worldState.nextShipInstanceSeq;
  final inferredStart = inferNextShipInstanceSeqFromFleets(fleets);
  if (nextSeq < inferredStart) nextSeq = inferredStart;

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    final regionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final localProvinceId = ProvinceId.localIdFrom(capitalProvinceId);

    _addStartingRegimentsForPlayer(
      player: player,
      capitalProvinceId: capitalProvinceId,
      regionId: regionId,
      regimentCount: regimentCount,
      unitsByRegion: unitsByRegion,
    );

    nextSeq = _mergeHomeFleetShipsForPlayer(
      player: player,
      regionId: regionId,
      localProvinceId: localProvinceId,
      shipCount: shipCount,
      fleets: fleets,
      fleetIndexById: fleetIndexById,
      nextSeq: nextSeq,
    );
  }

  return game.copyWith(
    worldState: game.worldState
        .mapBothRegionUnits((rid, _) => unitsByRegion[rid]!)
        .copyWith(fleets: fleets, nextShipInstanceSeq: nextSeq),
  );
}

String startingRegimentTypeForPlayer(Player player) {
  const fallbackId = 'peasant_levies';
  final stats = regimentStatsById(fallbackId);
  if (stats != null) return stats.id;
  return regimentCatalog.isNotEmpty ? regimentCatalog.first.id : fallbackId;
}

String startingShipTypeForPlayer(Player _) {
  return ShipEconomyCatalog.carrack.shipTypeId;
}

/// Formats per-landmass diagnostic parts shared by the OW/NW failure dumps.
List<String> _formatLandmassDiagnosticParts(
  MapTopology topology,
  Map<String, Set<String>> ppNbr,
) {
  final lms = landmassesSortedDesc(ppNbr);
  final lmParts = <String>[];
  for (var i = 0; i < lms.length; i++) {
    final lm = lms[i];
    var sea = 0;
    for (final p in lm.provinces) {
      if (isProvinceSeaBound(topology, p)) sea++;
    }
    lmParts.add('i=$i|sz=${lm.size}|sea=$sea|min=${lm.minProvinceId}');
  }
  return lmParts;
}

String lockedOwAssignFailureDiagnostics({
  required GameSetupConfig config,
  required MapTopology topology,
  required List<String> seaBoundIds,
}) {
  final ppNbr = provincePpNeighbours(topology);
  final sizes = ppLandComponentSizesSorted(topology);
  final partitionOk = oldWorldPartitionMatchesLockedProfile(topology);
  final feasibilityOk = lockedOldWorldRoleFeasibilityHolds(
    topology: topology,
    neighbours: ppNbr,
  );
  final lmParts = _formatLandmassDiagnosticParts(topology, ppNbr);
  var degMin = 1 << 30;
  var degMax = 0;
  var degSum = 0;
  for (final pid in ppNbr.keys) {
    final d = ppNbr[pid]?.length ?? 0;
    degSum += d;
    if (d < degMin) degMin = d;
    if (d > degMax) degMax = d;
  }
  final nProv = ppNbr.length;
  final degMean = nProv == 0 ? 0.0 : degSum / nProv;
  const cap = 16;
  final seaSample = seaBoundIds.length <= cap
      ? seaBoundIds.join(',')
      : '${seaBoundIds.take(cap).join(',')}…(+${seaBoundIds.length - cap})';
  return 'lockedOW_diag seed=${config.seed} nodes=${topology.nodes.length} '
      'edges=${topology.edges.length} nProv=$nProv ppSizes=$sizes '
      'partitionOk=$partitionOk feasibilityOk=$feasibilityOk '
      'seaboundCount=${seaBoundIds.length} seaboundSample=[$seaSample] '
      'ppDegMin=$degMin ppDegMax=$degMax ppDegMean=${degMean.toStringAsFixed(2)} '
      'landmasses=[${lmParts.join('; ')}]';
}

String lockedNwAssignFailureDiagnostics({
  required GameSetupConfig config,
  required MapTopology topology,
}) {
  final ppNbr = provincePpNeighbours(topology);
  final sizes = ppLandComponentSizesSorted(topology);
  final partitionOk = newWorldPartitionMatchesLockedProfile(topology);
  final feasibilityOk = lockedNewWorldRoleFeasibilityHolds(
    topology: topology,
    neighbours: ppNbr,
  );
  final lmParts = _formatLandmassDiagnosticParts(topology, ppNbr);
  return 'lockedNW_diag seed=${config.seed} nodes=${topology.nodes.length} '
      'edges=${topology.edges.length} nProv=${ppNbr.length} ppSizes=$sizes '
      'partitionOk=$partitionOk feasibilityOk=$feasibilityOk '
      'landmasses=[${lmParts.join('; ')}]';
}
