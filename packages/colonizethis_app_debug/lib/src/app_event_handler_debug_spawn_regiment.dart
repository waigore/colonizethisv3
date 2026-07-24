import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show appendMilitaryRegimentToArmy;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

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
    return (
      game: null,
      message:
          'Debug spawn ignored: unsupported regiment type ${event.regimentTypeId}.',
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
  final boundedCount = event.count > 25 ? 25 : event.count;
  final allUnits = <Unit>[
    ...guard.game.worldState.oldWorld.units,
    ...guard.game.worldState.newWorld.units,
  ];
  final usedUnitIds = {for (final unit in allUnits) unit.id};
  var nextUnitSeq = nextCanonicalUnitSequence(units: allUnits);
  var game = guard.game;
  for (var i = 0; i < boundedCount; i++) {
    final unitId = mintCanonicalUnitId(
      usedUnitIds: usedUnitIds,
      nextSequence: nextUnitSeq,
    );
    nextUnitSeq++;
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
