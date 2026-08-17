import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show appendMilitaryRegimentToArmy;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';
import 'debug_spawn_apply_helpers.dart';

/// Debug spawn military regiments at the human player's capital (console / dev tooling).
DebugCommandResult applyDebugRegimentSpawnAtCapital({
  required Game? currentGame,
  required SpawnDebugRegimentAtCapitalEvent event,
}) {
  final guard = resolveSpawnDebugGuards(
    currentGame: currentGame,
    label: DebugCommandLabel.spawn,
    playerId: event.humanPlayerId,
    requireHuman: true,
  );
  if (guard is DebugGuardFailure) return guard.result;
  guard as DebugGuardPass;
  final player = guard.player;
  if (RegimentEconomyCatalog.byId[event.regimentTypeId] == null) {
    return debugUnsupportedSpawnType(
      typeLabel: 'regiment',
      typeId: event.regimentTypeId,
    );
  }
  if (event.count < 1) {
    return debugCountBelowMin(DebugCommandLabel.spawn);
  }
  final capitalProvinceId = player.capitalProvinceId;
  if (capitalProvinceId == null || capitalProvinceId.isEmpty) {
    return debugNoCapitalProvince(DebugCommandLabel.spawn);
  }
  String? spawnRegionId;
  try {
    spawnRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
  } on StateError {
    spawnRegionId = null;
  }
  if (spawnRegionId == null || spawnRegionId.isEmpty) {
    return (
      game: null,
      message: 'Debug spawn ignored: invalid capital province id.',
    );
  }
  final boundedCount = boundDebugSpawnCount(event.count);
  final unitIds = mintDebugLandUnitIds(
    worldState: guard.game.worldState,
    count: boundedCount,
  );
  var game = guard.game;
  for (final unitId in unitIds) {
    final unit = Unit(
      id: unitId,
      type: event.regimentTypeId,
      ownerId: event.humanPlayerId,
      locationProvinceId: capitalProvinceId,
      tileKey: null,
      medals: 0,
      status: UnitStatus.idle,
      currentWork: null,
    );
    final updatedWorld = appendUnitsToRegion(
      game.worldState,
      spawnRegionId,
      [unit],
    );
    game = game.copyWith(worldState: updatedWorld);
    game = appendMilitaryRegimentToArmy(
      game,
      player,
      capitalProvinceId,
      unit.id,
    );
  }
  return (
    game: game,
    message:
        'Spawned $boundedCount ${event.regimentTypeId} at ${player.displayName} capital.',
  );
}
