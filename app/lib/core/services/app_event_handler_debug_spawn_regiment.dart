import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show appendMilitaryRegimentToArmy, kRegionNewWorld;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Debug spawn military regiments at the human player's capital (console / dev tooling).
DebugCommandResult applyDebugRegimentSpawnAtCapital({
  required Game? currentGame,
  required SpawnDebugRegimentAtCapitalEvent event,
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
  if (!player.isHuman) {
    return (
      game: null,
      message:
          'Debug spawn ignored: player ${event.humanPlayerId} is not human.',
    );
  }
  if (RegimentEconomyCatalog.byId[event.regimentTypeId] == null) {
    return (
      game: null,
      message:
          'Debug spawn ignored: unsupported regiment type ${event.regimentTypeId}.',
    );
  }
  if (event.count < 1) {
    return (game: null, message: 'Debug spawn ignored: count must be >= 1.');
  }
  final capitalProvinceId = player.capitalProvinceId;
  if (capitalProvinceId == null || capitalProvinceId.isEmpty) {
    return (
      game: null,
      message: 'Debug spawn ignored: player has no capital province.',
    );
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
    ...currentGame.worldState.oldWorld.units,
    ...currentGame.worldState.newWorld.units,
  ];
  final usedUnitIds = {for (final unit in allUnits) unit.id};
  var nextUnitSeq = nextCanonicalUnitSequence(units: allUnits);
  var game = currentGame;
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
    final world = game.worldState;
    final oldUnits = List<Unit>.from(world.oldWorld.units);
    final newUnits = List<Unit>.from(world.newWorld.units);
    if (spawnRegionId == kRegionNewWorld) {
      newUnits.add(unit);
    } else {
      oldUnits.add(unit);
    }
    final updatedWorld = world.copyWith(
      oldWorld: RegionData(
        provinces: world.oldWorld.provinces,
        units: oldUnits,
      ),
      newWorld: RegionData(
        provinces: world.newWorld.provinces,
        units: newUnits,
      ),
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
