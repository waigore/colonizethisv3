import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/debug_console_api.dart'
    show resolveCivilianSpawnTileKey;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';
import 'debug_spawn_apply_helpers.dart';

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
    return debugUnsupportedSpawnType(
      typeLabel: 'civilian',
      typeId: event.unitType,
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
  final boundedCount = boundDebugSpawnCount(event.count);
  final unitIds = mintDebugLandUnitIds(
    worldState: guard.game.worldState,
    count: boundedCount,
  );
  final spawned = <Unit>[
    for (final unitId in unitIds)
      Unit(
        id: unitId,
        type: event.unitType,
        ownerId: event.humanPlayerId,
        locationProvinceId: spawnProvinceId,
        tileKey: spawnTileKey,
      ),
  ];
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
