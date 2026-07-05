// Advanced-start unit and fleet bootstrap (steps 5–7). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'setup_logging.dart';

bool _isGpOwnedCivilianOrMilitaryUnit(Unit unit, String gpId) {
  if (unit.ownerId != gpId) return false;
  final role = unitRoleForType(unit.type);
  return role == UnitRole.military ||
      role == UnitRole.explorer ||
      role == UnitRole.civilianWorker ||
      role == UnitRole.spy ||
      role == UnitRole.merchant;
}

List<Unit> _filterGpCiviliansAndMilitary(List<Unit> units, Set<String> gpIds) {
  return [
    for (final unit in units)
      if (!gpIds.contains(unit.ownerId) ||
          !_isGpOwnedCivilianOrMilitaryUnit(unit, unit.ownerId))
        unit,
  ];
}

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
      'Unknown capital region "$capitalRegionId" for owner=$ownerId',
    );
  }
  final suffix = unitType.toLowerCase().replaceAll(' ', '_');
  for (var k = 1; k <= count; k++) {
    destination.add(
      Unit(
        id: '${ownerId}_adv_${suffix}_$k',
        type: unitType,
        ownerId: ownerId,
        locationProvinceId: capitalProvinceId,
        status: UnitStatus.idle,
        tileKey: capitalTileKey,
      ),
    );
  }
}

void _spawnRegimentsForPlayer({
  required Player player,
  required String capitalProvinceId,
  required String regionId,
  required List<String> regimentTypeIds,
  required Map<String, List<Unit>> unitsByRegion,
}) {
  if (regimentTypeIds.isEmpty) return;
  final destination = unitsByRegion[regionId];
  if (destination == null) {
    throw StateError(
      'Unknown capital region "$regionId" for player=${player.id}',
    );
  }
  for (var i = 0; i < regimentTypeIds.length; i++) {
    final typeId = regimentTypeIds[i];
    destination.add(
      Unit(
        id: '${player.id}_adv_${typeId}_reg${i + 1}',
        type: typeId,
        ownerId: player.id,
        locationProvinceId: capitalProvinceId,
        status: UnitStatus.idle,
      ),
    );
  }
}

Game applyAdvancedStartUnitsAndShips({
  required Game game,
  required AdvancedStartType startType,
}) {
  final civilianCounts = advancedStartCivilianCounts(startType);
  final regimentCount = advancedStartRegimentCount(startType);
  final shipCount = advancedStartCargoShipCount(startType);
  final gpIds = game.players.map((p) => p.id).toSet();

  var unitsByRegion = game.worldState.mutableUnitListsByRegion();
  for (final regionId in unitsByRegion.keys.toList()) {
    unitsByRegion[regionId] = _filterGpCiviliansAndMilitary(
      unitsByRegion[regionId]!,
      gpIds,
    );
  }

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    final capitalTile = player.capitalTile;
    if (capitalProvinceId == null || capitalTile == null) {
      setupLog.w(
        'logic: advanced start units skipped for ${player.id} — no capital',
      );
      continue;
    }
    final capitalTileKey = capitalTile.toTileKey();
    final capitalRegionId = ProvinceId.regionIdFrom(capitalProvinceId);

    for (final entry in civilianCounts.entries) {
      _spawnCivilianUnitsOfType(
        unitsByRegion: unitsByRegion,
        ownerId: player.id,
        capitalProvinceId: capitalProvinceId,
        capitalTileKey: capitalTileKey,
        capitalRegionId: capitalRegionId,
        unitType: entry.key,
        count: entry.value,
      );
    }

    final regimentTypes = advancedStartRegimentTypeIds(
      techUnlocked: player.techUnlocked,
      totalCount: regimentCount,
    );
    _spawnRegimentsForPlayer(
      player: player,
      capitalProvinceId: capitalProvinceId,
      regionId: capitalRegionId,
      regimentTypeIds: regimentTypes,
      unitsByRegion: unitsByRegion,
    );
  }

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
    if (regionId != kRegionOldWorld || shipCount <= 0) continue;

    final localProvinceId = ProvinceId.localIdFrom(capitalProvinceId);
    final fullProvinceId = '$regionId|$localProvinceId';
    final homeFleetId = homeFleetIdFor(player.id);
    final existingIndex = fleetIndexById[homeFleetId];
    final (seqAfter, newInstances) = mintShipInstances(
      nextShipInstanceSeq: nextSeq,
      typeIds: [
        for (var i = 0; i < shipCount; i++) kAdvancedStartCargoShipTypeId,
      ],
    );
    nextSeq = seqAfter;

    final homeFleet = Fleet(
      id: homeFleetId,
      ownerId: player.id,
      seaZoneId: null,
      inPortAtProvinceId: fullProvinceId,
      regionId: regionId,
      ships: newInstances,
    );
    if (existingIndex == null) {
      fleets.add(homeFleet);
      fleetIndexById[homeFleetId] = fleets.length - 1;
    } else {
      fleets[existingIndex] = homeFleet;
    }
  }

  var updated = game.copyWith(
    worldState: game.worldState
        .mapBothRegionUnits((rid, _) => unitsByRegion[rid]!)
        .copyWith(fleets: fleets, nextShipInstanceSeq: nextSeq),
  );
  return ensureMilitaryArmiesForGame(updated);
}
