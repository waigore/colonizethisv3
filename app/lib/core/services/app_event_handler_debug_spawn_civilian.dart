import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show kRegionNewWorld;
import 'package:colonizethis_logic/debug_console_api.dart'
    show resolveCivilianSpawnTileKey;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Debug spawn civilians at the human player's capital (console / dev tooling).
DebugCommandResult applyDebugCivilianSpawnAtCapital({
  required Game? currentGame,
  required SpawnDebugCivilianAtCapitalEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Debug spawn ignored: no active game.');
  }
  final player = findPlayerById(currentGame, event.humanPlayerId);
  if (player == null) {
    return (
      game: null,
      message: 'Debug spawn ignored: unknown player ${event.humanPlayerId}.',
    );
  }
  if (CivilianEconomyCatalog.byId[event.unitType] == null) {
    return (
      game: null,
      message:
          'Debug spawn ignored: unsupported civilian type ${event.unitType}.',
    );
  }
  if (event.count < 1) {
    return (game: null, message: 'Debug spawn ignored: count must be >= 1.');
  }
  final spawnTileKey = resolveCivilianSpawnTileKey(
    player: player,
    worldState: currentGame.worldState,
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
    ...currentGame.worldState.oldWorld.units,
    ...currentGame.worldState.newWorld.units,
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
  final world = currentGame.worldState;
  final oldUnits = List<Unit>.from(world.oldWorld.units);
  final newUnits = List<Unit>.from(world.newWorld.units);
  if (spawnRegionId == kRegionNewWorld) {
    newUnits.addAll(spawned);
  } else {
    oldUnits.addAll(spawned);
  }
  final updatedWorld = world.copyWith(
    oldWorld: RegionData(provinces: world.oldWorld.provinces, units: oldUnits),
    newWorld: RegionData(provinces: world.newWorld.provinces, units: newUnits),
  );
  return (
    game: currentGame.copyWith(worldState: updatedWorld),
    message:
        'Spawned ${spawned.length} ${event.unitType} at ${player.displayName} capital.',
  );
}
