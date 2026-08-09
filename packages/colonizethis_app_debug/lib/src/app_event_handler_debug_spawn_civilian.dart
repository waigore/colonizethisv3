import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/debug_console_api.dart'
    show resolveCivilianSpawnTileKey;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Debug spawn civilians at the human player's capital (console / dev tooling).
DebugCommandResult applyDebugCivilianSpawnAtCapital({
  required Game? currentGame,
  required SpawnDebugCivilianAtCapitalEvent event,
}) {
  final guard = resolveSpawnDebugGuards(
    currentGame: currentGame,
    label: DebugCommandLabel.spawn,
    playerId: event.humanPlayerId,
  );
  if (guard is DebugGuardFailure) return guard.result;
  guard as DebugGuardPass;
  final player = guard.player;
  if (CivilianEconomyCatalog.byId[event.unitType] == null) {
    return (
      game: null,
      message:
          'Debug spawn ignored: unsupported civilian type ${event.unitType}.',
    );
  }
  if (event.count < 1) {
    return debugCountBelowMin(DebugCommandLabel.spawn);
  }
  final spawnTileKey = resolveCivilianSpawnTileKey(
    player: player,
    worldState: guard.game.worldState,
  );
  final spawnProvinceId = Unit.provinceIdFromTileKey(spawnTileKey);
  final spawnRegionId = Unit.regionIdFromTileKey(spawnTileKey);
  if (spawnTileKey == null ||
      spawnProvinceId == null ||
      spawnRegionId == null) {
    return (
      game: null,
      message: 'Debug spawn ignored: player has no valid capital tile.',
    );
  }
  final boundedCount = event.count > 25 ? 25 : event.count;
  final allUnits = <Unit>[
    ...guard.game.worldState.oldWorld.units,
    ...guard.game.worldState.newWorld.units,
  ];
  final usedUnitIds = {for (final unit in allUnits) unit.id};
  var nextUnitSeq = nextCanonicalUnitSequence(units: allUnits);
  final spawned = <Unit>[];
  for (var i = 0; i < boundedCount; i++) {
    final unitId = mintCanonicalUnitId(
      usedUnitIds: usedUnitIds,
      nextSequence: nextUnitSeq,
    );
    nextUnitSeq++;
    spawned.add(
      Unit(
        id: unitId,
        type: event.unitType,
        ownerId: event.humanPlayerId,
        locationProvinceId: spawnProvinceId,
        tileKey: spawnTileKey,
      ),
    );
  }
  final updatedWorld = appendUnitsToRegion(
    guard.game.worldState,
    spawnRegionId,
    spawned,
  );
  return (
    game: guard.game.copyWith(worldState: updatedWorld),
    message:
        'Spawned ${spawned.length} ${event.unitType} at ${player.displayName} capital.',
  );
}
