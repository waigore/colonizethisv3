// SPEC/program/game-setup-pipeline.md §7e — starting units / military-naval bootstrap + locked diagnostics (importable library).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'faction_setup_helpers.dart';
import 'setup_unit_spawn.dart';

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
  civilianOwners() => setupCivilianOwnerRecords(game);

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
      spawnCivilianUnitsOfType(
        unitsByRegion: unitsByRegion,
        ownerId: ownerId,
        capitalProvinceId: capitalProvinceId,
        capitalTileKey: capitalTileKey,
        capitalRegionId: capitalRegionId,
        unitType: entry.key,
        count: entry.value,
        unitIdFor: baseSetupCivilianUnitId,
        includeExpectedRegionsInError: true,
      );
    }
  }

  return game.copyWith(
    worldState: game.worldState.mapBothRegionUnits(
      (rid, _) => unitsByRegion[rid]!,
    ),
  );
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
  final scratch = prepareHomeFleetMergeScratch(game.worldState);
  final fleets = scratch.fleets;
  final fleetIndexById = scratch.fleetIndexById;
  var nextSeq = scratch.nextSeq;

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    final regionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final localProvinceId = ProvinceId.localIdFrom(capitalProvinceId);

    if (regimentCount > 0) {
      final regimentTypeId = startingRegimentTypeForPlayer(player);
      spawnRegimentsAtCapital(
        ownerId: player.id,
        capitalProvinceId: capitalProvinceId,
        regionId: regionId,
        regimentTypeIds: List<String>.filled(regimentCount, regimentTypeId),
        unitsByRegion: unitsByRegion,
        unitIdFor: baseSetupRegimentUnitId,
        includeExpectedRegionsInError: true,
      );
    }

    nextSeq = mergeHomeFleetShips(
      ownerId: player.id,
      regionId: regionId,
      localProvinceId: localProvinceId,
      shipCount: shipCount,
      shipTypeId: startingShipTypeForPlayer(player),
      fleets: fleets,
      fleetIndexById: fleetIndexById,
      nextSeq: nextSeq,
      appendExistingShips: true,
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
