import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show appendMilitaryRegimentToArmy, kRegionNewWorld;
import 'package:colonizethis_logic/debug_console_api.dart'
    show resolveCivilianSpawnTileKey;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Debug spawn civilians at the human player's capital (console / dev tooling).
({Game? game, String message}) applyDebugCivilianSpawnAtCapital({
  required Game? currentGame,
  required SpawnDebugCivilianAtCapitalEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Debug spawn ignored: no active game.');
  }
  Player? player;
  for (final candidate in currentGame.players) {
    if (candidate.id == event.humanPlayerId) {
      player = candidate;
      break;
    }
  }
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
  var nextDebugSeq = _nextDebugSpawnSequence(
    units: allUnits,
    playerId: event.humanPlayerId,
    unitType: event.unitType,
  );
  final spawned = <Unit>[];
  for (var i = 0; i < boundedCount; i++) {
    spawned.add(
      Unit(
        id: 'debug_${event.humanPlayerId}_${_unitTypeIdSegment(event.unitType)}_${nextDebugSeq++}',
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

/// Debug spawn military regiments at the human player's capital (console / dev tooling).
({Game? game, String message}) applyDebugRegimentSpawnAtCapital({
  required Game? currentGame,
  required SpawnDebugRegimentAtCapitalEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Debug spawn ignored: no active game.');
  }
  Player? player;
  for (final candidate in currentGame.players) {
    if (candidate.id == event.humanPlayerId) {
      player = candidate;
      break;
    }
  }
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
  var nextDebugSeq = _nextDebugSpawnSequence(
    units: allUnits,
    playerId: event.humanPlayerId,
    unitType: event.regimentTypeId,
  );
  var game = currentGame;
  for (var i = 0; i < boundedCount; i++) {
    final unit = Unit(
      id: 'debug_${event.humanPlayerId}_${_unitTypeIdSegment(event.regimentTypeId)}_${nextDebugSeq++}',
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

String _unitTypeIdSegment(String unitType) {
  final lower = unitType.toLowerCase();
  return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

int _nextDebugSpawnSequence({
  required List<Unit> units,
  required String playerId,
  required String unitType,
}) {
  final prefix = 'debug_${playerId}_${_unitTypeIdSegment(unitType)}_';
  var maxSeen = 0;
  for (final unit in units) {
    if (!unit.id.startsWith(prefix)) {
      continue;
    }
    final suffix = unit.id.substring(prefix.length);
    final seq = int.tryParse(suffix);
    if (seq != null && seq > maxSeen) {
      maxSeen = seq;
    }
  }
  return maxSeen + 1;
}
