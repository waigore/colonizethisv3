// Advanced-start unit and fleet bootstrap (steps 5–7). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'setup_logging.dart';
import 'gp_old_world_tile_scan.dart';
import 'setup_unit_spawn.dart';

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

Game applyAdvancedStartUnitsAndShips({
  required Game game,
  required AdvancedStartType startType,
}) {
  final civilianCounts = advancedStartCivilianCounts(startType);
  final regimentCount = advancedStartRegimentCount(startType);
  final shipCount = advancedStartCargoShipCount(startType);
  final gpIds = gpIdsSortedFromPlayers(game).toSet();

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
      spawnCivilianUnitsOfType(
        unitsByRegion: unitsByRegion,
        ownerId: player.id,
        capitalProvinceId: capitalProvinceId,
        capitalTileKey: capitalTileKey,
        capitalRegionId: capitalRegionId,
        unitType: entry.key,
        count: entry.value,
        unitIdFor: advancedStartCivilianUnitId,
      );
    }

    final regimentTypes = advancedStartRegimentTypeIds(
      techUnlocked: player.techUnlocked,
      totalCount: regimentCount,
    );
    spawnRegimentsAtCapital(
      ownerId: player.id,
      capitalProvinceId: capitalProvinceId,
      regionId: capitalRegionId,
      regimentTypeIds: regimentTypes,
      unitsByRegion: unitsByRegion,
      unitIdFor: advancedStartRegimentUnitId,
    );
  }

  final scratch = prepareHomeFleetMergeScratch(game.worldState);
  final fleets = scratch.fleets;
  final fleetIndexById = scratch.fleetIndexById;
  var nextSeq = scratch.nextSeq;

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;
    final regionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final localProvinceId = ProvinceId.localIdFrom(capitalProvinceId);
    nextSeq = mergeHomeFleetShips(
      ownerId: player.id,
      regionId: regionId,
      localProvinceId: localProvinceId,
      shipCount: shipCount,
      shipTypeId: kAdvancedStartCargoShipTypeId,
      fleets: fleets,
      fleetIndexById: fleetIndexById,
      nextSeq: nextSeq,
      appendExistingShips: false,
    );
  }

  var updated = game.copyWith(
    worldState: game.worldState
        .mapBothRegionUnits((rid, _) => unitsByRegion[rid]!)
        .copyWith(fleets: fleets, nextShipInstanceSeq: nextSeq),
  );
  return ensureMilitaryArmiesForGame(updated);
}
